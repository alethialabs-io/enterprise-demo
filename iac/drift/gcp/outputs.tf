output "alethia_context" {
  description = "<project>/<environment>, echoed back to prove the injected context arrived."
  value       = "${var.alethia_project}/${var.alethia_environment}"
}

# The metadata KEY — the harness runs `gcloud compute project-info add-metadata --metadata <target>=<value>`.
output "drift_target" {
  description = "The project-metadata key the harness mutates out of band to induce drift."
  value       = google_compute_project_metadata_item.drift_probe.key
}

# No cluster_name output — see iac/drift/hetzner/outputs.tf for why that omission is load-bearing.
