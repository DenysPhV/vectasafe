resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.network_name}-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}
# 1. Створюємо роутер
resource "google_compute_router" "router" {
  name    = "vsafe-router"
  network = google_compute_network.vpc.id
  region  = var.region
}
# 2. Створюємо NAT (шлюз в інтернет)
resource "google_compute_router_nat" "nat" {
  name                               = "vsafe-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
# 3. Налаштування для приватної бази даних (Private Service Access)
resource "google_compute_global_address" "private_ip_address" {
  name          = "vsafe-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# Firewall: дозволяємо трафік від Load Balancer до наших VM
resource "google_compute_firewall" "allow_lb" {
  name    = "allow-health-check"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "8080"]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"] # Діапазони Google LB
  target_tags   = ["vectasafe-backend"]
}

resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "allow-iap-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Цей діапазон є статичним для сервісу Google IAP
  source_ranges = ["35.235.240.0/20"]

  # Застосовуємо тільки до наших бекенд-серверів
  target_tags = ["vectasafe-backend"]
}