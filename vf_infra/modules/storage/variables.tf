variable "project_id" {
  description = "Назва проекту"
  type        = string
}

variable "region" {
  description = "Регіон розгортання (напр. us-central1)"
  type        = string
}

variable "kms_key_link" {
  type = string
}