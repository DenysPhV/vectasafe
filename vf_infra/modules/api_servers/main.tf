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

      # Краще використовувати конкретний коміт або тег, а не гілку main
      git clone https://github.com/DenysPhV/vectasafe.git /opt/vectasafe
      cd /opt/vectasafe
      pip3 install -r requirements.txt

      # Створення користувача для сервісу (безпека)
      useradd -m -s /bin/bash vsafe_user
      chown -R vsafe_user:vsafe_user /opt/vectasafe

      # Створення Systemd сервісу
      cat <<EOF > /etc/systemd/system/vectasafe.service
      [Unit]
      Description=VectaSafe API
      After=network.target

      [Service]
      User=vsafe_user
      WorkingDirectory=/opt/vectasafe
      ExecStart=/usr/local/bin/uvicorn main:app --host 0.0.0.0 --port 8080
      Restart=always

      [Install]
      WantedBy=multi-user.target
      EOF

      systemctl daemon-reload
      systemctl enable vectasafe.service
      systemctl start vectasafe.service
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
    max_replicas = 5
    min_replicas = 2
    cpu_utilization {
      target = 0.6 # Масштабування при 60% CPU
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