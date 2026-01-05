# Health Check
resource "google_compute_health_check" "http_check" {
  name = "${var.lb_name}-health-check"

  http_health_check {
    port = 8080
  }
}

# 1. API Backend Service (Основний API)
resource "google_compute_backend_service" "api_backend" {
  name          = "${var.lb_name}-api-backend"
  health_checks = [google_compute_health_check.http_check.id]
  port_name     = "http"
  protocol      = "HTTP"

  backend {
    group = var.backend_instance_group
  }
}

# 2. Upload Backend Service (Новий сервіс для завантажень)
resource "google_compute_backend_service" "upload_backend" {
  name          = "${var.lb_name}-upload-backend"
  health_checks = [google_compute_health_check.http_check.id] # Можна створити окремий HC, якщо потрібно
  port_name     = "http"
  protocol      = "HTTP"

  backend {
    group = var.upload_instance_group
  }
}

# URL Map
resource "google_compute_url_map" "default" {
  name            = "${var.lb_name}-url-map"
  default_service = google_compute_backend_service.api_backend.id

  host_rule {
    hosts        = ["*"] # Або конкретний домен var.domain_name
    path_matcher = "main-paths"
  }

  path_matcher {
    name            = "main-paths"
    default_service = google_compute_backend_service.api_backend.id

    # Правило для Upload Service
    path_rule {
      paths   = ["/upload", "/upload/*"]
      service = google_compute_backend_service.upload_backend.id
    }
  }
}

# SSL Certificate
resource "google_compute_managed_ssl_certificate" "default" {
  name = "${var.lb_name}-cert"

  managed {
    domains = [var.domain_name]
  }
}

# HTTPS Proxy
resource "google_compute_target_https_proxy" "default" {
  name             = "${var.lb_name}-https-proxy"
  url_map          = google_compute_url_map.default.id
  ssl_certificates = [google_compute_managed_ssl_certificate.default.id]
}

# Forwarding Rule (Global IP)
resource "google_compute_global_forwarding_rule" "default" {
  name       = "${var.lb_name}-forwarding-rule"
  target     = google_compute_target_https_proxy.default.id
  port_range = "443"
}