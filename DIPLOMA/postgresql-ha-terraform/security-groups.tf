locals {
  internal_cidr = ["10.10.0.0/16"]
}

resource "yandex_vpc_security_group" "common" {
  name       = "${var.project_name}-sg-common"
  network_id = yandex_vpc_network.ha.id

  ingress {
    protocol       = "TCP"
    description    = "SSH inside project VPC"
    v4_cidr_blocks = local.internal_cidr
    port           = 22
  }
  ingress {
    protocol       = "TCP"
    description    = "Alertmanager to recovery controller"
    v4_cidr_blocks = ["10.10.30.31/32"]
    port           = 5000
  }
  ingress {
    protocol       = "ICMP"
    description    = "ICMP inside project VPC"
    v4_cidr_blocks = local.internal_cidr
  }

  ingress {
    protocol       = "TCP"
    description    = "node_exporter from internal monitoring network"
    v4_cidr_blocks = local.internal_cidr
    port           = 9100
  }

  egress {
    protocol       = "ANY"
    description    = "Outbound IPv4"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "bastion" {
  name       = "${var.project_name}-sg-bastion"
  network_id = yandex_vpc_network.ha.id

  ingress {
    protocol       = "TCP"
    description    = "SSH from administrator workstation"
    v4_cidr_blocks = [var.admin_cidr]
    port           = 22
  }
}

resource "yandex_vpc_security_group" "postgres" {
  name       = "${var.project_name}-sg-postgres"
  network_id = yandex_vpc_network.ha.id

  ingress {
    protocol       = "TCP"
    description    = "PostgreSQL"
    v4_cidr_blocks = local.internal_cidr
    port           = 5432
  }

  ingress {
    protocol       = "TCP"
    description    = "Patroni REST API"
    v4_cidr_blocks = local.internal_cidr
    port           = 8008
  }

  ingress {
    protocol       = "TCP"
    description    = "postgres_exporter"
    v4_cidr_blocks = local.internal_cidr
    port           = 9187
  }
}

resource "yandex_vpc_security_group" "etcd" {
  name       = "${var.project_name}-sg-etcd"
  network_id = yandex_vpc_network.ha.id

  ingress {
    protocol       = "TCP"
    description    = "etcd client traffic"
    v4_cidr_blocks = local.internal_cidr
    port           = 2379
  }

  ingress {
    protocol       = "TCP"
    description    = "etcd peer traffic"
    v4_cidr_blocks = local.internal_cidr
    port           = 2380
  }
}

resource "yandex_vpc_security_group" "haproxy" {
  name       = "${var.project_name}-sg-haproxy"
  network_id = yandex_vpc_network.ha.id

  ingress {
    protocol       = "TCP"
    description    = "HAProxy PostgreSQL write endpoint"
    v4_cidr_blocks = local.internal_cidr
    port           = 5000
  }

  ingress {
    protocol       = "TCP"
    description    = "HAProxy PostgreSQL read endpoint"
    v4_cidr_blocks = local.internal_cidr
    port           = 5001
  }

  ingress {
    protocol       = "TCP"
    description    = "HAProxy metrics/stats"
    v4_cidr_blocks = local.internal_cidr
    port           = 8404
  }
}

resource "yandex_vpc_security_group" "monitoring" {
  name       = "${var.project_name}-sg-monitoring"
  network_id = yandex_vpc_network.ha.id

  ingress {
    protocol       = "TCP"
    description    = "Grafana"
    v4_cidr_blocks = local.internal_cidr
    port           = 3000
  }

  ingress {
    protocol       = "TCP"
    description    = "Prometheus"
    v4_cidr_blocks = local.internal_cidr
    port           = 9090
  }

  ingress {
    protocol       = "TCP"
    description    = "Alertmanager"
    v4_cidr_blocks = local.internal_cidr
    port           = 9093
  }
}
