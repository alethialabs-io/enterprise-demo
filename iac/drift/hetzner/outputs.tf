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
