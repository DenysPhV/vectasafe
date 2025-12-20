output "network_id" {
  value       = google_compute_network.vpc.id
  description = "ID створеної VPC"
}

output "subnetwork_id" {
  value       = google_compute_subnetwork.subnet.id
  description = "ID підмережі для використання серверами"
}