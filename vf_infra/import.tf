# 1. Отримуємо службовий акаунт GCS для вашого проекту
data "google_storage_project_service_account" "gcs_account" {
  project = var.project_id
}

# data "google_secret_manager_secret_version" "db_pass" {
#   secret  = "vsafe-db-password"
#   version = "latest"
# }

data "archive_file" "backend_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../backend"
  output_path = "${path.module}/backend.zip"
  excludes    = ["__pycache__", "venv", ".git", ".env"]
}