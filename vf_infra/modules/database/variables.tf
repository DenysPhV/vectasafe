variable "project_id" {
  description = "Назва проекту"
  type        = string
}

variable "region" {
  description = "Регіон розгортання (напр. us-central1)"
  type        = string
}

variable "db_password" {
  type = string
  sensitive = true
}