variable "project_id" {
  description = "Назва проекту"
  type        = string
}

variable "project_name" {
  description = "NAME проекту GCP"
  type        = string
}

variable "region" {
  description = "Регіон розгортання (напр. us-central1)"
  type        = string
}

variable "environment" {
  type = string
}

variable "kms_key_link" {
  type = string
}

variable "bucket_name" {
  type = string
} # Було vault_bucket_name в root, тут назвемо просто bucket_name

variable "force_destroy" {
  type = bool
}