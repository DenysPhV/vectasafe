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

variable "machine_type" {
  description = "Тип VM (напр. e2-medium або n1-standard-4 для GPU)"
  type        = string
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

variable "lb_name" {
  description = "Load balancer name of state"
  type        = string
}