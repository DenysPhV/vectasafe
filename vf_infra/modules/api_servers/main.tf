# Створюємо ідентичність для серверів VectaSafe
resource "google_service_account" "vsafe_sa" {
  account_id   = "vsafe-api-sa"
  display_name = "Service Account for VectaSafe API & Workers"
}

# Надаємо доступ до бакета зі сховищем (Розділ 7 Архітектури)
resource "google_storage_bucket_iam_member" "vault_access" {
  bucket = var.vault_bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.vsafe_sa.email}"
}

# Даємо дозвіл сервісному акаунту читати конкретний секрет
resource "google_secret_manager_secret_iam_member" "db_pass_access" {
  project   = var.project_id
  secret_id = var.db_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.vsafe_sa.email}"
}

# Instance Template - Конфігурація "імутабельної" машини
resource "google_compute_instance_template" "api_tpl" {
  name_prefix  = "vectasafe-tpl-"
  machine_type = var.machine_type
  tags         = ["vectasafe-backend"]

  disk {
    source_image = "debian-cloud/debian-11"
    boot         = true
  }

  network_interface {
    subnetwork = var.subnetwork_id
  }

  service_account {
    email  = google_service_account.vsafe_sa.email
    scopes = ["cloud-platform"]
  }

  metadata = {
# Ми використовуємо templatefile, або просто інтерполяцію змінних, якщо це heredoc
    startup-script = templatefile("${path.root}/scripts/startup.sh", {
      db_secret_id       = var.db_secret_id
      db_connection_name = var.db_connection_name
    })
  }
}

# Managed Instance Group (MIG)
resource "google_compute_region_instance_group_manager" "mig" {
  name               = "vectasafe-mig"
  base_instance_name = "vsafe"
  region             = var.region

  version {
    instance_template = google_compute_instance_template.api_tpl.id
  }

  named_port {
    name = "http"
    port = 8080
  }
}

# Autoscaler - Динамічне масштабування (Розділ 8 діаграми)
resource "google_compute_region_autoscaler" "autoscaler" {
  name   = "vectasafe-autoscaler"
  region = var.region
  target = google_compute_region_instance_group_manager.mig.id

  autoscaling_policy {
    max_replicas = var.max_replicas
    min_replicas = var.min_replicas
    # Масштабування по CPU (60%)
    cpu_utilization {
      target = 0.6 
    }
    # Масштабування по пам'яті (RAM) - потребує Ops Agent
    # Використовуємо метрику агента
    metric {
      name   = "agent.googleapis.com/memory/percent_used"
      target = 70  # Масштабуємося, якщо RAM > 70%
      type   = "GAUGE"
    }
  }
}

# Дозвіл на запис логів
resource "google_project_iam_member" "logging" {
  project = var.project_id # Потрібно додати змінну project_id в variables.tf цього модуля
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.vsafe_sa.email}"
}

# Дозвіл на запис метрик (CPU, RAM usage)
resource "google_project_iam_member" "monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.vsafe_sa.email}"
}