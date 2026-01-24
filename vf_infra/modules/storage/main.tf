resource "google_storage_bucket" "vault" {
  name          = "${var.project_name}-${var.bucket_name}-${var.environment}" # Унікальне ім'я
  location      = var.region
  force_destroy = var.force_destroy # Безпека даних для dev можна true

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = var.kms_key_link # Опціонально для Enterprise KMS
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE" # Автоматичний перехід у Cold Storage (Розділ 3)
    }
  }
}