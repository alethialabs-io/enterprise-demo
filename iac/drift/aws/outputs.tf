output "alethia_context" {
  description = "<project>/<environment>, echoed back to prove the injected context arrived."
  value       = "${var.alethia_project}/${var.alethia_environment}"
}

# The parameter NAME — the harness runs `aws ssm put-parameter --name <target> --overwrite`.
output "drift_target" {
  description = "The SSM parameter the harness mutates out of band to induce drift."
  value       = aws_ssm_parameter.drift_probe.name
}

# No cluster_name output — see iac/drift/hetzner/outputs.tf for why that omission is load-bearing.
