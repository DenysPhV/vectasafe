output "connection_name" {
  description = "Connection name for Cloud SQL instance (project:region:instance)"
  value       = google_sql_database_instance.vectasafe_db.connection_name
}

output "db_user_name" {
  description = "Database user name"
  value       = google_sql_user.vsafe_api_users.name
}

output "db_secret_id" {
  description = "ID секрету пароля БД в Secret Manager"
  value       = google_secret_manager_secret.db_pass_secret.secret_id
}

output "private_ip" {
  description = "The private IP address of the main database instance"
  value       = google_sql_database_instance.vectasafe_db.private_ip_address
}