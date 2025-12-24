resource "google_storage_bucket" "vault" {
  name          = "vsafe-vault-${var.project_id}" # Унікальне ім'я
  location      = var.region
  force_destroy = false # Безпека даних для dev можна true

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
      type = "SetStorageClass"
      storage_class = "COLDLINE" # Автоматичний перехід у Cold Storage (Розділ 3)
    }
  }
}