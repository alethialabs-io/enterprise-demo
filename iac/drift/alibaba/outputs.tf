output "alethia_context" {
  description = "<project>/<environment>, echoed back to prove the injected context arrived."
  value       = "${var.alethia_project}/${var.alethia_environment}"
}

# The bucket NAME — the harness runs `aliyun oss bucket-tagging … oss://<target> drift_marker#<value>`.
output "drift_target" {
  description = "The OSS bucket the harness mutates out of band to induce drift."
  value       = alicloud_oss_bucket.drift_probe.bucket
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
