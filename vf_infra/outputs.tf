# Вивід назви бакета для завантаження файлів
output "vault_bucket_name" {
  value       = module.storage.bucket_name
  description = "Реальна назва бакета VectaSafe"
}

# Вивід зовнішньої IP-адреси Load Balancer
output "load_balancer_ip" {
  value       = google_compute_global_forwarding_rule.default.ip_address
  description = "IP адреса вашого API Gateway"
}


