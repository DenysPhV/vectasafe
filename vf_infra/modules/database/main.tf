resource "google_sql_database_instance" "vectasafe_db" {
  name             = "vsafe-db-${var.project_id}"
  database_version = "POSTGRES_14"
  region           = var.region

  settings {
    tier = "db-g1-small"
    
    # Налаштування безпеки
    ip_configuration {
      ipv4_enabled = true
      private_network = var.network_id
      ssl_mode = "ENCRYPTED_ONLY"
      authorized_networks {
        name  = "office-vpn"
        value = var.static_ip
      }
    }

    backup_configuration {
      enabled = true
      start_time = "03:00"
    }
  }

  # Захист від випадкового видалення через Terraform
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_sql_database" "database" {
  name     = "vectasafe"
  instance = google_sql_database_instance.vectasafe_db.name
}

# Створення користувача для API
resource "google_sql_user" "vsafe_api_user" {
  name     = "vsafe_admin"
  instance = google_sql_database_instance.vectasafe_db.name
  password = var.db_password
}