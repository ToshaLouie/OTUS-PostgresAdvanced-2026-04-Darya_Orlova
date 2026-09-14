#!/usr/bin/env python3

import logging
import subprocess

from flask import Flask, request, jsonify

app = Flask(__name__)

# -------------------------------------------------------------------
# Logging
# -------------------------------------------------------------------

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s"
)

logger = logging.getLogger("recovery-controller")


# -------------------------------------------------------------------
# Paths
# -------------------------------------------------------------------

ANSIBLE_DIR = "/home/odd/postgresql-ha/ansible"
INVENTORY = f"{ANSIBLE_DIR}/inventory/hosts.yml"


# -------------------------------------------------------------------
# Prometheus instance -> Ansible host
# -------------------------------------------------------------------

INSTANCE_TO_HOST = {
    # PostgreSQL
    "10.10.10.11:9100": "pg-01",
    "10.10.20.11:9100": "pg-02",
    "10.10.30.11:9100": "pg-03",

    # etcd
    "10.10.10.21:9100": "etcd-01",
    "10.10.20.21:9100": "etcd-02",
    "10.10.30.21:9100": "etcd-03",

    # HAProxy
    "10.10.20.30:9100": "haproxy-01",

    # Monitoring
    "10.10.10.31:9100": "prometheus-01",
    "10.10.20.31:9100": "grafana-01",
    "10.10.30.31:9100": "alertmanager-01",
}


# -------------------------------------------------------------------
# Alert -> recovery playbook
# Названия alertname должны совпадать с Prometheus alerts.yml
# -------------------------------------------------------------------

RECOVERY_RULES = {
    # node_exporter unavailable
    "NodeDown": "recovery-node-exporter.yml",

    # Эти сценарии подключим следующими:
    "PostgreSQLDown": "recovery-postgres.yml",
    "PatroniDown": "recovery-patroni.yml",
    "EtcdDown": "recovery-etcd.yml",
    "HAProxyDown": "recovery-haproxy.yml",
}


def run_playbook(playbook, recovery_host):
    """
    Run an Ansible recovery playbook for one host.
    """

    playbook_path = f"{ANSIBLE_DIR}/playbooks/{playbook}"

    command = [
        "/usr/bin/ansible-playbook",
        "-i",
        INVENTORY,
        playbook_path,
        "-e",
        f"recovery_host={recovery_host}",
    ]

    logger.info(
        "Running recovery: host=%s playbook=%s",
        recovery_host,
        playbook
    )

    try:
        result = subprocess.run(
            command,
            cwd=ANSIBLE_DIR,
            capture_output=True,
            text=True,
            timeout=180
        )

        logger.info(
            "Recovery finished: host=%s playbook=%s rc=%s",
            recovery_host,
            playbook,
            result.returncode
        )

        if result.stdout:
            logger.info("Ansible stdout:\n%s", result.stdout)

        if result.stderr:
            logger.warning("Ansible stderr:\n%s", result.stderr)

        return {
            "host": recovery_host,
            "playbook": playbook,
            "returncode": result.returncode,
            "stdout": result.stdout[-3000:],
            "stderr": result.stderr[-2000:],
        }

    except subprocess.TimeoutExpired:
        logger.exception(
            "Recovery timed out for host=%s",
            recovery_host
        )

        return {
            "host": recovery_host,
            "playbook": playbook,
            "status": "timeout",
            "returncode": 124,
        }

    except Exception as exc:
        logger.exception(
            "Recovery failed for host=%s",
            recovery_host
        )

        return {
            "host": recovery_host,
            "playbook": playbook,
            "status": "error",
            "error": str(exc),
            "returncode": 1,
        }


@app.route("/recover", methods=["POST"])
def recover():
    data = request.get_json(silent=True) or {}

    logger.info("Received webhook: %s", data)

    status = data.get("status")
    alerts = data.get("alerts", [])

    # Recovery запускаем только для FIRING.
    # RESOLVED игнорируем.
    if status != "firing":
        return jsonify({
            "status": "ignored",
            "reason": "alert is not firing"
        }), 200

    if not alerts:
        return jsonify({
            "status": "ignored",
            "reason": "no alerts received"
        }), 200

    results = []

    for alert in alerts:
        labels = alert.get("labels", {})

        alertname = labels.get("alertname")
        instance = labels.get("instance")

        logger.info(
            "Processing alert: alertname=%s instance=%s",
            alertname,
            instance
        )

        # Проверяем, знаем ли мы такой recovery-сценарий
        playbook = RECOVERY_RULES.get(alertname)

        if not playbook:
            logger.info(
                "Ignoring unsupported alert: %s",
                alertname
            )

            results.append({
                "alert": alertname,
                "instance": instance,
                "status": "ignored",
                "reason": "no recovery rule"
            })
            continue

        # Определяем Ansible host
        recovery_host = INSTANCE_TO_HOST.get(instance)

        if not recovery_host:
            logger.warning(
                "Unknown instance: %s",
                instance
            )

            results.append({
                "alert": alertname,
                "instance": instance,
                "status": "ignored",
                "reason": "unknown instance"
            })
            continue

        result = run_playbook(
            playbook=playbook,
            recovery_host=recovery_host
        )

        result["alert"] = alertname
        result["instance"] = instance

        results.append(result)

    return jsonify(results), 200


@app.route("/health", methods=["GET"])
def health():
    return jsonify({
        "status": "ok",
        "service": "recovery-controller"
    }), 200


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=5000
    )
