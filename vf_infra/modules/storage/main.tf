resource "google_storage_bucket" "vault" {
  name          = "vsafe-vault-${var.project_id}" # Унікальне ім'я
  location      = var.region
  force_destroy = false # Захист від випадкового видалення даних клієнтів

  # Увімкнення версійності (Розділ 31 архітектури)
  versioning {
    enabled = true
  }

  # Шифрування (Zero Knowledge)
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

# Створюємо в'язку ключів у вашому регіоні
resource "google_kms_key_ring" "vsafe_keyring" {
  name     = "vsafe-keyring"
  location = var.region
}

# Створюємо ключ шифрування
resource "google_kms_crypto_key" "vsafe_storage_key" {
  name     = "vsafe-storage-key"
  key_ring = google_kms_key_ring.vsafe_keyring.id
  
  lifecycle {
    prevent_destroy = true # Захист від видалення ключів (Disaster Recovery)
  }
}

data "google_storage_project_service_account" "gcs_account" {}

resource "google_kms_crypto_key_iam_member" "storage_kms_admin" {
  crypto_key_id = google_kms_crypto_key.vsafe_storage_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
}