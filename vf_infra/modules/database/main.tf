# 1. Створюємо сам секрет (контейнер) в Secret Manager
resource "google_secret_manager_secret" "db_pass_secret" {
  secret_id = "vsafe-db-password"

  replication {
    auto {}
  }
}

# 2. Створюємо версію секрету (записуємо туди значення)
resource "google_secret_manager_secret_version" "db_pass_version" {
  secret = google_secret_manager_secret.db_pass_secret.id

  # Беремо пароль зі змінної і кладемо в Secret Manager
  secret_data = var.db_password
}

resource "google_sql_database_instance" "vectasafe_db" {
  name             = "vsafe-db-${var.project_id}"
  database_version = "POSTGRES_14"
  region           = var.region

  settings {
    tier = "db-custom-1-3840"
    # ВМИКАЄМО MULTI-AZ (High Availability)
    availability_type = "REGIONAL"
    # Налаштування безпеки
    ip_configuration {
      ipv4_enabled    = true
      private_network = var.network_id
      ssl_mode        = "ENCRYPTED_ONLY"
      authorized_networks {
        name  = "office-vpn"
        value = var.static_ip
      }
    }

    backup_configuration {
      enabled            = true
      binary_log_enabled = true # Потрібно для Point-in-time recovery та HA
      start_time         = "03:00"
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
resource "google_sql_user" "vsafe_api_users" {
  name     = "vsafe_admin"
  instance = google_sql_database_instance.vectasafe_db.name
  password = var.db_password
}