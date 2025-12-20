output "bucket_name" {
  value       = google_storage_bucket.vault.name
  description = "Назва бакета для сховища VectaSafe"
}