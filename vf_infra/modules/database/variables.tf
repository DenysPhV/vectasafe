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

variable "network_id" {
  description = "ID мережі VPC для приватного з'єднання"
  type        = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_name" {
  type        = string
  sensitive   = true
}

variable "static_ip" {
  type = string
}

variable "db_tier" {
  type = string
}

variable "availability_type" {
  type = string
}  