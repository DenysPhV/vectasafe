resource "google_project_service" "kms_api" {
  project = var.project_id
  service = "cloudkms.googleapis.com"

  disable_on_destroy = false
}

resource "random_id" "kms_suffix" {
  byte_length = 4

  keepers = {
    # Генерувати новий суфікс, лише якщо змінюється Key Ring (або можна забрати keepers для повної рандомізації)
    key_ring_name = var.key_ring_name
  }
}

resource "google_kms_key_ring" "key_ring" {
  name       = "${var.project_name}-${var.key_ring_name}-${var.environment}-${random_id.kms_suffix.hex}"
  location   = var.region
  project  = var.project_id
  depends_on = [google_project_service.kms_api]
}

resource "google_kms_crypto_key" "storage_key" {
  name     = "${var.key_name}-${var.environment}-${random_id.kms_suffix.hex}"
  key_ring = google_kms_key_ring.key_ring.id
  rotation_period = "7776000s" # 90 days

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_kms_crypto_key_iam_binding" "gcs_kms_binding" {
  crypto_key_id = google_kms_crypto_key.storage_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:${var.gcs_service_account_email}",
  ]
}
