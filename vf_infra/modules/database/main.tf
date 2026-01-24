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
  name                = "${var.project_name}-db"
  database_version    = "POSTGRES_14"
  region              = var.region
  deletion_protection = false

  settings {
    tier              = var.db_tier
    availability_type = var.availability_type

    # Налаштування безпеки
    ip_configuration {
      ipv4_enabled    = true
      private_network = var.network_id
      ssl_mode        = "ENCRYPTED_ONLY"
      authorized_networks {
        name  = "${var.project_name}-vpn-${var.environment}"
        value = var.static_ip
      }
    }

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
      start_time                     = "03:00"
    }
  }

  # Захист від випадкового видалення через Terraform
  lifecycle {
    prevent_destroy = false
  }
}

resource "google_sql_database" "database" {
  name     = "${var.project_name}-db"
  instance = google_sql_database_instance.vectasafe_db.name
}

# Створення користувача для API
resource "google_sql_user" "vsafe_api_users" {
  name     = var.db_name
  instance = google_sql_database_instance.vectasafe_db.name
  password = var.db_password
}