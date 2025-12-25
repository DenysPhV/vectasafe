variable "project_id" {
  description = "Назва проекту"
  type        = string
}

variable "region" {
  description = "Регіон розгортання (напр. us-central1)"
  type        = string
}

variable "network_id" {
  description = "ID мережі VPC для приватного з'єднання"
  type        = string
}

variable "db_password" {
  type = string
  sensitive = true
}

variable "static_ip" {
  type = string
}