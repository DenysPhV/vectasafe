resource "google_kms_key_ring" "vsafe_ring" {
  name     = "vsafe-key-ring"
  location = var.region
}

resource "google_kms_crypto_key" "vsafe_storage_key" {
  name     = "vsafe-storage-key"
  key_ring = google_kms_key_ring.vsafe_ring.id
}

resource "google_project_service" "kms_api" {
  project = var.project_id
  service = "cloudkms.googleapis.com"

  disable_on_destroy = false
}

resource "google_kms_crypto_key_iam_binding" "gcs_kms_binding" {
  crypto_key_id = google_kms_crypto_key.vsafe_storage_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}",
  ]
}

module "network" {
  source       = "./modules/network"
  network_name = "vectasafe-prod"
  region       = var.region
  
}

module "storage" {
  source     = "./modules/storage"
  project_id = var.project_id
  region     = var.region
  kms_key_link = google_kms_crypto_key.vsafe_storage_key.id
}

module "api_servers" {
  source        = "./modules/api_servers"
  region        = var.region
  subnetwork_id = module.network.subnetwork_id # Зв'язка модулів
  vault_bucket_name = module.storage.bucket_name
  machine_type  = "e2-standard-2"
  min_replicas  = 2
  max_replicas  = 10
}

# 1. Отримуємо службовий акаунт GCS для вашого проекту
data "google_storage_project_service_account" "gcs_account" {
  project = var.project_id
}


