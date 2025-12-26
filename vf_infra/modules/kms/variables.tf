variable "project_id" {
  description = "ID проекту GCP"
  type        = string
}

variable "region" {
  description = "Регіон розгортання ключів"
  type        = string
}

variable "key_ring_name" {
  description = "Назва Key Ring"
  type        = string
}

variable "key_name" {
  description = "Назва крипто-ключа"
  type        = string
}

variable "gcs_service_account_email" {
  description = "Email сервісного акаунту GCS для надання прав доступу до ключів"
  type        = string
}