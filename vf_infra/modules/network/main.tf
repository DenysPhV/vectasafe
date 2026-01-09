resource "google_compute_network" "vpc" {
  name                    = "${var.project_name}-${var.network_name}-${var.environment}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.project_name}-${var.network_name}-subnet-${var.environment}"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
}
# 1. Створюємо роутер
resource "google_compute_router" "router" {
  name    = "${var.project_name}-router-${var.environment}"
  network = google_compute_network.vpc.id
  region  = var.region
}
# 2. Створюємо NAT (шлюз в інтернет)
resource "google_compute_router_nat" "nat" {
  name                               = "${var.project_name}-nat-${var.environment}"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
# 3. Налаштування для приватної бази даних (Private Service Access)
resource "google_compute_global_address" "private_ip_address" {
  name          = "${var.project_name}-private-ip-${var.environment}"
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
  name    = "${var.project_name}-allow-health-check-${var.environment}"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "8080"]
  }
  # prebring
  source_ranges = var.private_source_ranges
  target_tags   = ["${var.project_name}-backend-${var.environment}"]
}

resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "${var.project_name}-allow-iap-ssh-${var.environment}"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Цей діапазон є статичним для сервісу Google IAP
  source_ranges = var.allow_iap_ssh_source_ranges

  # Застосовуємо тільки до наших бекенд-серверів
  target_tags = ["${var.project_name}-backend-${var.environment}"]
}

# --- IAP SSH Firewall Rule ---
# Дозволяє підключатися по SSH тільки через Identity-Aware Proxy
# gcloud compute ssh --tunnel-through-iap ...
resource "google_compute_firewall" "iap_ssh" {
  name    = "${var.project_name}-${var.network_name}-allow-iap-ssh-${var.environment}"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Це діапазон IP, який використовує Google IAP для підключення до твоїх VM
  source_ranges = var.allow_iap_ssh_source_ranges

  # Застосовуємо до всіх інстансів (або можна використати target_tags)
  target_tags = ["${var.project_name}-backend-${var.environment}"]
}