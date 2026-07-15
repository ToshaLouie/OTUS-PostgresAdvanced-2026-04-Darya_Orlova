data "yandex_vpc_network" "otus" {
  name = var.network_name
}

data "yandex_vpc_subnet" "otus" {
  name = var.subnet_name
}

data "yandex_compute_image" "ubuntu_2404" {
  family = "ubuntu-2404-lts"
}

resource "yandex_vpc_security_group" "postgres_access" {
  name        = "${var.vm_name}-postgres-access"
  description = "SSH and PostgreSQL access for ${var.vm_name}"
  network_id  = data.yandex_vpc_network.otus.id

  ingress {
    protocol       = "TCP"
    description    = "SSH"
    port           = 22
    v4_cidr_blocks = var.ssh_allowed_cidr
  }

  ingress {
    protocol       = "TCP"
    description    = "PostgreSQL"
    port           = 5432
    v4_cidr_blocks = var.postgres_allowed_cidr
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_compute_instance" "otus9" {
  name                      = var.vm_name
  hostname                  = var.vm_name
  zone                      = var.zone
  platform_id               = "standard-v3"
  allow_stopping_for_update = true

  resources {
    cores         = 2
    memory        = 8
    core_fraction = 100
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2404.id
      type     = "network-ssd"
      size     = var.boot_disk_size_gb
    }
  }

  network_interface {
    subnet_id = data.yandex_vpc_subnet.otus.id
    nat       = true

    security_group_ids = [
      var.existing_security_group_id,
      yandex_vpc_security_group.postgres_access.id
    ]
  }

  metadata = {
    user-data = <<-CLOUD_CONFIG
      #cloud-config
      users:
        - name: ubuntu
          groups: [sudo]
          shell: /bin/bash
          sudo: ALL=(ALL) NOPASSWD:ALL
          ssh_authorized_keys:
            - ${var.ssh_public_key}
        - name: odd
          groups: [sudo]
          shell: /bin/bash
          sudo: ALL=(ALL) NOPASSWD:ALL
          ssh_authorized_keys:
            - ${var.ssh_public_key}
      ssh_pwauth: false
      disable_root: true
      package_update: true
      packages:
        - python3
        - python3-apt

    CLOUD_CONFIG
  }
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/ansible/inventory.ini"

  content = <<-INVENTORY
    [postgres]
    ${yandex_compute_instance.otus9.network_interface[0].nat_ip_address}

    [postgres:vars]
    ansible_user=ubuntu
    ansible_ssh_private_key_file=${pathexpand(var.ssh_private_key_path)}
    ansible_python_interpreter=/usr/bin/python3
  INVENTORY
}
