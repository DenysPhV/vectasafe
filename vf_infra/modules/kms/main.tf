resource "google_project_service" "kms_api" {
  project = var.project_id
  service = "cloudkms.googleapis.com"

  disable_on_destroy = false
}

resource "google_kms_key_ring" "key_ring" {
  name       = var.key_ring_name
  location   = var.region
  depends_on = [google_project_service.kms_api]
}

resource "google_kms_crypto_key" "storage_key" {
  name     = var.key_name
  key_ring = google_kms_key_ring.key_ring.id
}

resource "google_kms_crypto_key_iam_binding" "gcs_kms_binding" {
  crypto_key_id = google_kms_crypto_key.storage_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:${var.gcs_service_account_email}",
  ]
}
