output "instance_group" {
  value       = google_compute_region_instance_group_manager.mig.instance_group
  description = "Посилання на групу інстансів для Load Balancer"
}