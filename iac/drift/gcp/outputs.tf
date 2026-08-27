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

# The module's DECLARED baseline, echoed so the harness can confirm the probe applied at a known
# starting point before it mutates anything. Read once, immediately after apply
# (t2_byo_iac_run_test.go): without it a later "it drifted" could mean the probe was never at
# baseline in the first place.
#
# It echoes the VARIABLE, not the live resource, and that is the point — the live value is what the
# out-of-band mutation changes, and comparing the live value against itself would prove nothing.
output "drift_marker" {
  description = "The baseline value the probe was applied with. The harness asserts it is \"baseline\"."
  value       = var.drift_marker
}

# No cluster_name output — see iac/drift/hetzner/outputs.tf for why that omission is load-bearing.
