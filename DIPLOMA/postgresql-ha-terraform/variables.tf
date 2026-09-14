variable "project_name" {
  description = "Project prefix used for resource names."
  type        = string
  default     = "postgresql-ha"
}

variable "default_zone" {
  description = "Default availability zone for the provider."
  type        = string
  default     = "ru-central1-a"
}

variable "admin_cidr" {
  description = "Public IPv4 CIDR allowed to SSH to ansible-01. Prefer YOUR_PUBLIC_IP/32."
  type        = string
}

variable "ssh_user" {
  description = "Linux user created by the Ubuntu image metadata."
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key_path" {
  description = "Path to the local SSH public key."
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "subnets" {
  description = "Availability zones and CIDRs."
  type = map(object({
    zone = string
    cidr = string
  }))

  default = {
    a = {
      zone = "ru-central1-a"
      cidr = "10.10.10.0/24"
    }
    b = {
      zone = "ru-central1-b"
      cidr = "10.10.20.0/24"
    }
    c = {
      zone = "ru-central1-d"
      cidr = "10.10.30.0/24"
    }
  }
}

variable "vms" {
  description = "Virtual machines in the lab."
  type = map(object({
    role          = string
    subnet        = string
    private_ip    = string
    cores         = number
    memory        = number
    core_fraction = number
    disk_size     = number
    disk_type     = string
    public_ip     = bool
  }))

  default = {
    pg-01 = {
      role          = "postgres"
      subnet        = "a"
      private_ip    = "10.10.10.11"
      cores         = 2
      memory        = 4
      core_fraction = 100
      disk_size     = 30
      disk_type     = "network-ssd"
      public_ip     = false
    }
    pg-02 = {
      role          = "postgres"
      subnet        = "b"
      private_ip    = "10.10.20.11"
      cores         = 2
      memory        = 4
      core_fraction = 100
      disk_size     = 30
      disk_type     = "network-ssd"
      public_ip     = false
    }
    pg-03 = {
      role          = "postgres"
      subnet        = "c"
      private_ip    = "10.10.30.11"
      cores         = 2
      memory        = 4
      core_fraction = 100
      disk_size     = 30
      disk_type     = "network-hdd"
      public_ip     = false
    }

    etcd-01 = {
      role          = "etcd"
      subnet        = "a"
      private_ip    = "10.10.10.21"
      cores         = 2
      memory        = 2
      core_fraction = 50
      disk_size     = 10
      disk_type     = "network-ssd"
      public_ip     = false
    }
    etcd-02 = {
      role          = "etcd"
      subnet        = "b"
      private_ip    = "10.10.20.21"
      cores         = 2
      memory        = 2
      core_fraction = 50
      disk_size     = 10
      disk_type     = "network-ssd"
      public_ip     = false
    }
    etcd-03 = {
      role          = "etcd"
      subnet        = "c"
      private_ip    = "10.10.30.21"
      cores         = 2
      memory        = 2
      core_fraction = 50
      disk_size     = 10
      disk_type     = "network-ssd"
      public_ip     = false
    }

    haproxy-01 = {
      role          = "haproxy"
      subnet        = "b"
      private_ip    = "10.10.20.30"
      cores         = 2
      memory        = 2
      core_fraction = 50
      disk_size     = 10
      disk_type     = "network-hdd"
      public_ip     = false
    }

    prometheus-01 = {
      role          = "monitoring"
      subnet        = "a"
      private_ip    = "10.10.10.31"
      cores         = 2
      memory        = 4
      core_fraction = 50
      disk_size     = 10
      disk_type     = "network-hdd"
      public_ip     = true
    }
    grafana-01 = {
      role          = "monitoring"
      subnet        = "b"
      private_ip    = "10.10.20.31"
      cores         = 2
      memory        = 2
      core_fraction = 50
      disk_size     = 10
      disk_type     = "network-hdd"
      public_ip     = true
    }
    alertmanager-01 = {
      role          = "monitoring"
      subnet        = "c"
      private_ip    = "10.10.30.31"
      cores         = 2
      memory        = 2
      core_fraction = 50
      disk_size     = 10
      disk_type     = "network-hdd"
      public_ip     = false
    }

    ansible-01 = {
      role          = "ansible"
      subnet        = "bastion"
      private_ip    = "10.10.40.10"
      cores         = 2
      memory        = 2
      core_fraction = 50
      disk_size     = 10
      disk_type     = "network-hdd"
      public_ip     = true
    }

  }
}

variable "telegram_bot_token" {
  description = "Telegram Bot API token"
  type        = string
  sensitive   = true
}

variable "telegram_chat_id" {
  description = "Telegram chat ID for PostgreSQL HA alerts"
  type        = string
}
