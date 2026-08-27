output "alethia_context" {
  description = "<project>/<environment>, echoed back to prove the injected context arrived."
  value       = "${var.alethia_project}/${var.alethia_environment}"
}

# The resource-group NAME — the harness runs `az group update --name <target> --set tags.drift_marker=…`.
output "drift_target" {
  description = "The resource group the harness mutates out of band to induce drift."
  value       = azurerm_resource_group.drift_probe.name
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
