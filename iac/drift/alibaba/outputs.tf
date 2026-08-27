output "alethia_context" {
  description = "<project>/<environment>, echoed back to prove the injected context arrived."
  value       = "${var.alethia_project}/${var.alethia_environment}"
}

# The bucket NAME — the harness runs `aliyun oss bucket-tagging … oss://<target> drift_marker#<value>`.
output "drift_target" {
  description = "The OSS bucket the harness mutates out of band to induce drift."
  value       = alicloud_oss_bucket.drift_probe.bucket
}

# No cluster_name output — see iac/drift/hetzner/outputs.tf for why that omission is load-bearing.

# drift_marker is the LIVE value of the probe's one mutable field, and the reason this output must
# read the RESOURCE rather than `var.drift_marker`.
#
# The harness establishes a baseline from this output, mutates the live value out of band, refreshes,
# and expects the posture to flip. An output wired to the VARIABLE would echo the baseline forever:
# the module would report in-sync through a real drift, and the whole drift/heal proof would pass
# while measuring nothing. Reading the resource attribute is what makes the assertion falsifiable.
#
# hetzner/addons run 32996889745 — the first byo-iac run on any cloud — failed with
# `the module emitted no "drift_marker" output`, which is what surfaced this. It was missing on ALL
# FIVE clouds, so all five are fixed here rather than the one that happened to run first.
output "drift_marker" {
  description = "LIVE value of the probe's drift marker, read back from the resource."
  value       = alicloud_oss_bucket.drift_probe.tags["drift_marker"]
}
