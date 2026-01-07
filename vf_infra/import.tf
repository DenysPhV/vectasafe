# 1. Отримуємо службовий акаунт GCS для вашого проекту
data "google_storage_project_service_account" "gcs_account" {
  project = var.project_id
}

# data "google_secret_manager_secret_version" "db_pass" {
#   secret  = "vsafe-db-password"
#   version = "latest"
# }

