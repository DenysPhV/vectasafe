module "kms" {
  source        = "./modules/kms"
  project_id    = var.project_id
  region        = var.region
  key_name      = var.key_name
  key_ring_name = var.key_ring_name

  # Передаємо email, знайдений через data source
  gcs_service_account_email = data.google_storage_project_service_account.gcs_account.email_address
}

module "network" {
  source       = "./modules/network"
  network_name = "vectasafe-prod"
  region       = var.region
}

module "api_servers" {
  source            = "./modules/api_servers"
  region            = var.region
  subnetwork_id     = module.network.subnetwork_id # Зв'язка модулів
  vault_bucket_name = module.storage.bucket_name
  machine_type      = "e2-standard-2"
  min_replicas      = 2
  max_replicas      = 10
}

module "load_balancer" {
  source     = "./modules/load_balancer"
  project_id = var.project_id
  region     = var.region
  lb_name    = "vectasafe-prod" # Можна змінювати для dev/stage
  # Отримуємо ID групи інстансів з модуля api_servers
  backend_instance_group = module.api_servers.instance_group
  domain_name            = var.domain_name
}

# 1. Створюємо сам секрет (контейнер) в Secret Manager
resource "google_secret_manager_secret" "db_pass_secret" {
  secret_id = "vsafe-db-password"

  replication {
    auto {}
  }
}

# 2. Створюємо версію секрету (записуємо туди значення)
resource "google_secret_manager_secret_version" "db_pass_version" {
  secret = google_secret_manager_secret.db_pass_secret.id

  # Беремо пароль зі змінної і кладемо в Secret Manager
  secret_data = var.db_password
}

module "database" {
  source      = "./modules/database"
  project_id  = var.project_id
  region      = var.region
  db_password = google_secret_manager_secret_version.db_pass_version.secret_data
  network_id  = module.network.network_id
  static_ip   = var.static_ip
}

module "storage" {
  source       = "./modules/storage"
  project_id   = var.project_id
  region       = var.region
  kms_key_link = module.kms.key_id
}



