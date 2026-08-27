# alethia_context is the injection proof. It can only read "<project>/<environment>" if the runner's
# frozen TF_VAR_alethia_* actually reached this module; a module that fell back to the variable
# defaults emits "local/dev" instead, and the harness compares against the real pair.
output "alethia_context" {
  description = "<project>/<environment>, echoed back to prove the injected context arrived."
  value       = "${var.alethia_project}/${var.alethia_environment}"
}

# drift_target is the identifier the out-of-band mutation addresses. For hetzner that is the
# placement group NAME, because the harness runs:
#   hcloud placement-group add-label --overwrite <target> drift_marker=<value>
output "drift_target" {
  description = "The placement group the harness mutates out of band to induce drift."
  value       = hcloud_placement_group.drift_probe.name
}

# ── THERE IS DELIBERATELY NO cluster_name OUTPUT. ──
#
# That single omission is what keeps Alethia's entire post-apply spine off: deploy.go runs the
# kubeconfig → CNI → ArgoCD → add-on tail only `if result.ClusterName != ""`. A customer module that
# emitted one would silently opt into a pipeline it has no cluster for.
#
# The harness asserts the absence MECHANICALLY against the state's outputs, so this comment is a
# reason rather than the guarantee.

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
