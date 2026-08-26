output "alethia_context" {
  description = "<project>/<environment>, echoed back to prove the injected context arrived."
  value       = "${var.alethia_project}/${var.alethia_environment}"
}

# The resource-group NAME — the harness runs `az group update --name <target> --set tags.drift_marker=…`.
output "drift_target" {
  description = "The resource group the harness mutates out of band to induce drift."
  value       = azurerm_resource_group.drift_probe.name
}

# No cluster_name output — see iac/drift/hetzner/outputs.tf for why that omission is load-bearing.
