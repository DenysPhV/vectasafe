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
    startup-script = <<-EOT
      #! /bin/bash
      apt-get update
      apt-get install -y python3-pip git
      
      # Клон репозиторію (потрібен токен або публічний доступ)
      git clone https://github.com/DenysPhV/vectasafe.git /opt/vectasafe
      
      cd /opt/vectasafe
      pip3 install -r requirements.txt
      
      # Запуск API (приклад)
      nohup uvicorn main:app --host 0.0.0.0 --port 8080 &
    EOT
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
    max_replicas    = 5
    min_replicas    = 2
    cpu_utilization {
      target = 0.6 # Масштабування при 60% CPU
    }
  }
}