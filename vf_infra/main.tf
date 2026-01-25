module "kms" {
  source       = "./modules/kms"
  project_id   = var.project_id
  project_name = var.project_name
  environment  = var.environment

  region        = var.region
  key_name      = var.key_name
  key_ring_name = var.key_ring_name
  # Передаємо email, знайдений через data source
  gcs_service_account_email = data.google_storage_project_service_account.gcs_account.email_address
}

module "network" {
  source       = "./modules/network"
  project_name = var.project_name
  environment  = var.environment

  network_name                = var.network_name
  region                      = var.region
  subnet_cidr                 = var.subnet_cidr
  private_source_ranges       = var.private_source_ranges
  allow_iap_ssh_source_ranges = var.allow_iap_ssh_source_ranges
}

resource "google_storage_bucket_object" "backend_code" {
  name   = "backend-${data.archive_file.backend_zip.output_md5}.zip"
  bucket = module.storage.bucket_name # Беремо ім'я бакета з модуля storage
  source = data.archive_file.backend_zip.output_path
}

module "api_servers" {
  source            = "./modules/api_servers"
  region            = var.region
  project_id        = var.project_id
  project_name      = var.project_name
  environment       = var.environment
  subnetwork_id     = module.network.subnetwork_id
  vault_bucket_name = module.storage.bucket_name
  machine_type      = var.machine_type

  # Параметри скейлінгу
  min_replicas = var.min_replicas
  max_replicas = var.max_replicas

  db_private_ip = module.database.private_ip
  db_password   = var.db_password
  db_connection_name = module.database.connection_name
  db_secret_id       = module.database.db_secret_id

  code_bucket   = module.storage.bucket_name # Де лежить код
  code_archive  = google_storage_bucket_object.backend_code.name # Ім'я архіву

  github_token       = var.github_token

  depends_on = [ module.database, module.storage ]
}

module "load_balancer" {
  source       = "./modules/load_balancer"
  project_id   = var.project_id
  project_name = var.project_name
  environment  = var.environment
  region       = var.region
  lb_name      = var.lb_name
  # API Backend
  backend_instance_group = module.api_servers.instance_group
  # Тимчасово направляємо upload трафік теж на api_servers, 
  # поки не створимо окремий модуль для upload-воркерів
  upload_instance_group = module.api_servers.instance_group
  domain_name           = var.domain_name
}


module "database" {
  source       = "./modules/database"
  project_id   = var.project_id
  project_name = var.project_name
  environment  = var.environment
  region       = var.region
  network_id   = module.network.network_id
  static_ip    = var.static_ip

  db_password       = var.db_password #google_secret_manager_secret_version.db_pass_version.secret_data
  db_tier           = var.db_tier
  db_name           = var.db_name
  availability_type = var.db_availability_type
  depends_on        = [module.network]
}

module "storage" {
  source       = "./modules/storage"
  project_id   = var.project_id
  project_name = var.project_name
  environment  = var.environment
  region       = var.region
  kms_key_link = module.kms.key_id

  bucket_name   = var.vault_bucket_name
  force_destroy = var.force_destroy_bucket # Дозволяємо видалення в DEV

  depends_on = [module.kms]
}

resource "google_project_service" "sqladmin" {
  project            = var.project_id
  service            = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

