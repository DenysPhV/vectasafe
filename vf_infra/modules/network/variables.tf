variable "project_name" {
  description = "NAME проекту GCP"
  type        = string
}

variable "network_name" {
  description = "Назва VPC мережі для VectaSafe"
  type        = string
}

variable "region" {
  description = "Регіон розгортання (напр. us-central1)"
  type        = string
}

variable "environment" {
  type = string
}

variable "subnet_cidr" {
  type = string
}

variable "private_source_ranges" {
  type = list(string)
}

variable "allow_iap_ssh_source_ranges" {
  type = list(string)
}
