terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

# THE PROBE. One bucket, owned by this module, whose `drift_marker` LABEL is the single mutable
# value. Empty, so it is free; `force_destroy` so a destroy can never be held up by an object
# nothing put there.
#
# WHY A BUCKET AND NOT PROJECT METADATA. This was a `google_compute_project_metadata_item`, and it
# could not be created at all: `Error 403: Required 'compute.projects.setCommonInstanceMetadata'
# permission for 'projects/itgix-adp', forbidden`. The fix is NOT to grant that permission. Common
# instance metadata includes `ssh-keys`, so that one verb grants SSH into every VM in the project —
# and the credential being granted it is the one a CUSTOMER's own OpenTofu executes under. In a
# shared project that is a straightforward escalation, and it would be a privileged shortcut the
# e2e takes that a customer's real setup would not.
#
# A bucket label is scoped to a resource this module owns, and the e2e identity already holds
# `roles/storage.admin`, so the scoped probe needs no new grant whatsoever.
#
# The name carries the environment suffix because bucket names are GLOBALLY unique — two concurrent
# runs must not contend for one, exactly as the metadata key needed before.
resource "google_storage_bucket" "drift_probe" {
  name          = "alethia-byo-iac-${local.suffix}"
  location      = var.alethia_region != "" ? var.alethia_region : "EU"
  force_destroy = true

  # No objects are ever written here; this only stops a bucket-level ACL surprise.
  uniform_bucket_level_access = true

  # Destroy must actually destroy. GCS soft-delete defaults to a 7-day retention, which would leave
  # every run's probe bucket lingering — and "teardown verified, the account is empty" is the bar
  # this whole leg is asserting. 0 disables it.
  soft_delete_policy {
    retention_duration_seconds = 0
  }

  labels = {
    drift_marker = var.drift_marker
    managed_by   = "alethia-byo-iac-e2e"
  }
}
