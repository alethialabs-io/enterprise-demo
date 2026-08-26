# A customer's OWN OpenTofu, run by Alethia on the customer's behalf.
#
# NO BACKEND BLOCK, deliberately. The runner writes zzz_alethia_backend_override.tf (and its .tofu
# twin) to force the HTTP state proxy, and a backend declared here would be the thing it overrides.
# The absence is what makes "state never touched the customer's own sink" checkable rather than
# asserted.
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.48"
    }
  }
}

# THE PROBE. One resource, one mutable label.
#
# A placement group is the cheapest thing on Hetzner that carries labels and costs nothing to hold:
# it is a scheduling constraint, not a machine. Drift has to be induced on something REAL, and it
# should not be something that bills by the hour to prove a posture.
resource "hcloud_placement_group" "drift_probe" {
  name = local.name
  type = "spread"

  labels = {
    drift_marker = var.drift_marker
    managed_by   = "alethia-byo-iac-e2e"
  }
}
