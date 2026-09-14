locals {
  role_security_groups = {
    postgres   = [yandex_vpc_security_group.postgres.id]
    etcd       = [yandex_vpc_security_group.etcd.id]
    haproxy    = [yandex_vpc_security_group.haproxy.id]
    monitoring = [yandex_vpc_security_group.monitoring.id]
    ansible    = [yandex_vpc_security_group.bastion.id]
  }
}

resource "yandex_compute_instance" "vm" {
  for_each = var.vms

  name        = each.key
  hostname    = each.key
  zone        = each.value.subnet == "bastion" ? "ru-central1-a" : var.subnets[each.value.subnet].zone
  platform_id = "standard-v3"

  allow_stopping_for_update = true

  resources {
    cores         = each.value.cores
    memory        = each.value.memory
    core_fraction = each.value.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      type     = each.value.disk_type
      size     = each.value.disk_size
    }
  }

  network_interface {
    subnet_id  = each.value.subnet == "bastion" ? yandex_vpc_subnet.bastion.id : yandex_vpc_subnet.ha[each.value.subnet].id
    ip_address = each.value.private_ip
    nat        = each.value.public_ip

    security_group_ids = concat(
      [yandex_vpc_security_group.common.id],
      local.role_security_groups[each.value.role]
    )
  }

  metadata = {
    user-data = <<-EOF
    #cloud-config
    users:
      - name: ${var.ssh_user}
        groups: sudo
        shell: /bin/bash
        sudo: ALL=(ALL) NOPASSWD:ALL
        ssh_authorized_keys:
          - ${trimspace(file(pathexpand(var.ssh_public_key_path)))}

    ssh_pwauth: false
    disable_root: true
    EOF
  }

  labels = {
    project = var.project_name
    role    = each.value.role
  }

  lifecycle {
    prevent_destroy = true

    ignore_changes = [
      boot_disk[0].initialize_params[0].image_id
    ]
  }
}