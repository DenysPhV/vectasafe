# Health Check: Перевірка "живучості" VM (Розділ 3.2 Kubernetes for Developers)
resource "google_compute_health_check" "http_check" {
  name = "http-health-check"
  http_health_check {
    port = 8080
  }
}

# Backend Service
resource "google_compute_backend_service" "default" {
  name          = "vectasafe-backend-service"
  health_checks = [google_compute_health_check.http_check.id]
  backend {
    group = module.api_servers.instance_group 
  }
}

# URL Map & Forwarding Rule (Вхідна точка)
resource "google_compute_url_map" "url_map" {
  name            = "vectasafe-lb"
  default_service = google_compute_backend_service.default.id
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "vectasafe-forwarding-rule"
  target     = google_compute_target_http_proxy.http_proxy.id
  port_range = "80"
}

resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "vectasafe-proxy"
  url_map = google_compute_url_map.url_map.id
}