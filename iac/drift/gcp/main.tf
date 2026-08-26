terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

# THE PROBE. A project-metadata item is free and holds one mutable string. It is PROJECT-scoped
# rather than instance-scoped, so the key carries the environment suffix — two concurrent runs in
# the same project must not contend for one key.
resource "google_compute_project_metadata_item" "drift_probe" {
  key   = "alethia-byo-iac-${local.suffix}"
  value = var.drift_marker
}
