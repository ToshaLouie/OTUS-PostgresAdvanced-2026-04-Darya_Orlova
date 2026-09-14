resource "yandex_vpc_network" "ha" {
  name = "${var.project_name}-network"
}

resource "yandex_vpc_gateway" "nat" {
  name = "${var.project_name}-nat"

  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "private_egress" {
  name       = "${var.project_name}-private-egress"
  network_id = yandex_vpc_network.ha.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat.id
  }
}

resource "yandex_vpc_subnet" "bastion" {
  name           = "${var.project_name}-subnet-bastion"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.ha.id
  v4_cidr_blocks = ["10.10.40.0/24"]

}

resource "yandex_vpc_subnet" "ha" {
  for_each = var.subnets

  name           = "${var.project_name}-subnet-${each.key}"
  zone           = each.value.zone
  network_id     = yandex_vpc_network.ha.id
  v4_cidr_blocks = [each.value.cidr]

  # Gives private-only VMs outbound Internet access through the shared NAT gateway.
  route_table_id = yandex_vpc_route_table.private_egress.id
}
