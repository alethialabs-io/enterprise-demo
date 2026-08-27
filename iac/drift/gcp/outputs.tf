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

# drift_marker is the LIVE value of the probe's one mutable field, and it must read the RESOURCE
# rather than `var.drift_marker`.
#
# An output wired to the VARIABLE would echo "baseline" forever: the harness asserts this equals the
# baseline immediately after apply, and against the variable that assertion is trivially true no
# matter what was actually applied. Reading the resource is what makes it falsifiable — it proves
# the probe really is at a known starting point, which is the whole reason a later "it drifted"
# means anything.
#
# Here that is the bucket LABEL, because this module's probe is a bucket (see main.tf for why it is
# not project metadata). The harness mutates it with
# `gcloud storage buckets update gs://<target> --update-labels=drift_marker=<value>`.
output "drift_marker" {
  description = "LIVE value of the probe's drift marker, read back from the resource."
  value       = google_storage_bucket.drift_probe.labels["drift_marker"]
}

# No cluster_name output — see iac/drift/hetzner/outputs.tf for why that omission is load-bearing.
