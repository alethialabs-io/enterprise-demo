output "alethia_context" {
  description = "<project>/<environment>, echoed back to prove the injected context arrived."
  value       = "${var.alethia_project}/${var.alethia_environment}"
}

# The bucket NAME — the harness runs
# `gcloud storage buckets update gs://<target> --update-labels=drift_marker=<value>`.
# `--update-labels` merges, so `managed_by` survives the out-of-band mutation.
output "drift_target" {
  description = "The bucket whose drift_marker label the harness mutates out of band to induce drift."
  value       = google_storage_bucket.drift_probe.name
}

# No cluster_name output — see iac/drift/hetzner/outputs.tf for why that omission is load-bearing.
