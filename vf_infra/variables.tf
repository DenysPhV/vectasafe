variable "project_id" {
  description = "Назва проекту"
  type        = string
}

variable "region" {
  description = "Регіон розгортання (напр. us-central1)"
  type        = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "static_ip" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "key_ring_name" {
  description = "Назва Key Ring"
  type        = string
}

variable "key_name" {
  description = "Назва крипто-ключа"
  type        = string
}