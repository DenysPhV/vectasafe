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
  source             = "./modules/api_servers"
  region             = var.region
  project_id         = var.project_id
  subnetwork_id      = module.network.subnetwork_id
  vault_bucket_name  = module.storage.bucket_name
  machine_type       = var.machine_type
  min_replicas       = 2
  max_replicas       = 20
  db_connection_name = module.database.connection_name
  db_secret_id       = module.database.db_secret_id
}

module "load_balancer" {
  source     = "./modules/load_balancer"
  project_id = var.project_id
  region     = var.region
  lb_name    = "vectasafe-${var.lb_name}" # Можна змінювати для prod/stage
  # API Backend
  backend_instance_group = module.api_servers.instance_group
  # Тимчасово направляємо upload трафік теж на api_servers, 
  # поки не створимо окремий модуль для upload-воркерів
  upload_instance_group = module.api_servers.instance_group
  domain_name           = var.domain_name
}


module "database" {
  source      = "./modules/database"
  project_id  = var.project_id
  region      = var.region
  db_password = var.db_password #google_secret_manager_secret_version.db_pass_version.secret_data
  network_id  = module.network.network_id
  static_ip   = var.static_ip
  depends_on  = [module.network]
}

module "storage" {
  source       = "./modules/storage"
  project_id   = var.project_id
  region       = var.region
  kms_key_link = module.kms.key_id
  depends_on = [module.kms]
}



