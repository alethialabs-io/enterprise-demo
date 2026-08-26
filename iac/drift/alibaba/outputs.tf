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
