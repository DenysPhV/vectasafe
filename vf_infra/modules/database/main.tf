resource "google_sql_database_instance" "vectasafe_db" {
  name             = "vsafe-db-instance"
  database_version = "POSTGRES_14"
  region           = var.region

  settings {
    tier = "db-f1-micro" # Для MVP/Dev
    
    # Налаштування безпеки (Розділ 9 Архітектури)
    ip_configuration {
      ipv4_enabled = true
      # В ідеалі: обмежити дозволені IP або використовувати Private Service Connect
    }

    backup_configuration {
      enabled = true
      start_time = "03:00" # Нічний бекап для Disaster Recovery
    }
  }
}

resource "google_sql_database" "database" {
  name     = "vectasafe"
  instance = google_sql_database_instance.vectasafe_db.name
}