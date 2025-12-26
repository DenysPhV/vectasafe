output "key_id" {
  value       = google_kms_crypto_key.storage_key.id
  description = "Повний ідентифікатор ключа KMS для використання в інших модулях"
}