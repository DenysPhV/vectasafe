# Вивід назви бакета для завантаження файлів
output "vault_bucket_name" {
  value       = module.storage.bucket_name
  description = "Реальна назва бакета VectaSafe"
}

# Вивід зовнішньої IP-адреси Load Balancer
output "load_balancer_ip" {
  value       = module.load_balancer.load_balancer_ip
  description = "IP адреса вашого API Gateway"
}


