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

  security_policy = google_compute_security_policy.security_policy.id
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

  security_policy = google_compute_security_policy.security_policy.id
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

# --- Cloud Armor Security Policy ---
resource "google_compute_security_policy" "security_policy" {
  name        = "${var.lb_name}-security-policy"
  description = "Basic WAF & DDoS protection"

  # Правило 1: Захист від SQL Injection (примитивний приклад, базовий набір)
  rule {
    action   = "deny(403)"
    priority = "1000"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sqli-v33-stable')"
      }
    }
    description = "Block SQL Injection attacks"
  }

  # Правило 2: Захист від XSS
  rule {
    action   = "deny(403)"
    priority = "1001"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss-v33-stable')"
      }
    }
    description = "Block XSS attacks"
  }

  # Правило за замовчуванням: Дозволити все інше
  rule {
    action   = "allow"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default allow"
  }
}

# --- ТИМЧАСОВИЙ ДОСТУП ПО HTTP (для тесту без домену) ---

# 1. HTTP Проксі (те ж саме, що HTTPS, але без сертифікату)
resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "${var.lb_name}-http-proxy"
  url_map = google_compute_url_map.default.id
}

# 2. Правило переадресації для порту 80
resource "google_compute_global_forwarding_rule" "http_rule" {
  name       = "${var.lb_name}-http-forwarding-rule"
  target     = google_compute_target_http_proxy.http_proxy.id
  port_range = "80"
}