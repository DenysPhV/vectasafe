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

variable "backend_instance_group" {
  description = "Посилання на Instance Group, куди направляти трафік"
  type        = string
}

variable "upload_instance_group" {
  description = "Посилання на Instance Group для Upload Service"
  type        = string
}

variable "domain_name" {
  description = "Доменне ім'я для SSL сертифікату (напр. api.vectasafe.com)"
  type        = string
}

variable "lb_name" {
  description = "Load balancer name of state"
  type        = string
}