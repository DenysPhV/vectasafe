variable "machine_type" {
  description = "Тип VM (напр. e2-medium або n1-standard-4 для GPU)"
  type        = string
  default     = "e2-medium"
}

variable "region" {
  type        = string
}

variable "subnetwork_id" {
  description = "ID підмережі, отриманий від модуля network"
  type        = string
}

variable "min_replicas" {
  description = "Мінімальна кількість VM (Розділ 8 діаграми)"
  type        = number
  default     = 2
}

variable "max_replicas" {
  description = "Максимальна кількість VM для обробки піків"
  type        = number
  default     = 5
}

variable "vault_bucket_name" {
  type        = string
}