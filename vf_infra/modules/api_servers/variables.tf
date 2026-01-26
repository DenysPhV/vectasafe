variable "project_id" {
  description = "Назва проекту"
  type        = string
}

variable "project_name" {
  description = "NAME проекту GCP"
  type        = string
}

variable "region" {
  type = string
}

variable "environment" {
  type = string
}

variable "machine_type" {
  description = "Тип VM (напр. e2-medium або n1-standard-4 для GPU)"
  type        = string
}

variable "db_secret_id" {
  description = "ID секрету з паролем від БД"
  type        = string
}

variable "subnetwork_id" {
  description = "ID підмережі, отриманий від модуля network"
  type        = string
}

variable "min_replicas" {
  description = "Мінімальна кількість VM (Розділ 8 діаграми)"
  type        = number
  default     = 2
}

variable "max_replicas" {
  description = "Максимальна кількість VM для обробки піків"
  type        = number
  default     = 5
}

variable "vault_bucket_name" {
  type = string
}

variable "db_connection_name" {
  description = "Connection Name екземпляра Cloud SQL (project:region:instance)"
  type        = string
}

variable "db_private_ip" {
  description = "Private IP of the Cloud SQL instance"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "github_token" {
  type      = string
  sensitive = true
}

variable "github_repo_url" {
  description = "URL to clone the code from"
  type        = string
}