variable "project_id" {
  description = "ID проекту GCP"
  type        = string
}

variable "project_name" {
  description = "NAME проекту GCP"
  type        = string
}

variable "region" {
  description = "Регіон розгортання"
  type        = string
}

variable "environment" {
  type = string
}

# --- Network ---
variable "network_name" {
  description = "Назва VPC мережі"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR блоку підмережі"
  type        = string
}

variable "private_source_ranges" {
  type = list(string)
}

variable "allow_iap_ssh_source_ranges" {
  type = list(string)
}

# --- Database ---
variable "db_password" {
  description = "Пароль адміністратора БД"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Name адміністратора БД"
  type        = string
  sensitive   = true
}

variable "db_tier" {
  description = "Тип інстансу БД (напр. db-f1-micro для dev)"
  type        = string
}

variable "db_availability_type" {
  description = "Тип доступності: ZONAL (дешевше) або REGIONAL (HA)"
  type        = string
}

variable "static_ip" {
  description = "Статична IP для доступу (VPN/Office)"
  type        = string
}

# --- Compute / Autoscaling ---
variable "machine_type" {
  description = "Тип VM для воркерів"
  type        = string
}

variable "min_replicas" {
  description = "Мінімальна кількість інстансів"
  type        = number
}

variable "max_replicas" {
  description = "Максимальна кількість інстансів"
  type        = number
}

# --- Storage / Security ---
variable "vault_bucket_name" {
  description = "Назва бакета для сховища"
  type        = string
}

variable "force_destroy_bucket" {
  description = "Чи дозволяти видалення бакета з даними (true для dev)"
  type        = bool
}

variable "key_ring_name" {
  description = "Назва Key Ring KMS"
  type        = string
}

variable "key_name" {
  description = "Назва крипто-ключа KMS"
  type        = string
}

# --- Load Balancer ---
variable "domain_name" {
  description = "Доменне ім'я"
  type        = string
}

variable "lb_name" {
  description = "Назва Load Balancer"
  type        = string
}

variable "github_token" {
  description = "GitHub токен"
  type        = string
  sensitive   = true
}