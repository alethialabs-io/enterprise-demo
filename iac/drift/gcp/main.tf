# Alethia BYO-IaC drift probe — GCP.
#
# See ../README.md for the full contract. In short: this is the customer's OWN module,
# applied by Alethia's runner under its federated identity, whose only job is to own one
# mutable value so that a change made OUTSIDE Alethia can be detected by a later
# refresh-only DETECT_DRIFT.
#
# NO `backend` block (the runner injects the HTTP state-proxy override) and NO
# `cluster_name` output (that output is what would make the runner continue into the
# kubeconfig → CNI → ArgoCD tail; without it the run stops after state-to-proxy).

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

# Credentials are ambient: ActivateGcpOIDC writes a Workload Identity Federation
# external-account file and sets GOOGLE_APPLICATION_CREDENTIALS plus the project vars before
# dispatch. Keyless — there is no service-account key anywhere in this repo.
provider "google" {}

variable "alethia_project" {
  type        = string
  default     = ""
  description = "Injected by the Alethia runner as TF_VAR_alethia_project. NOTE: this is the Alethia project name, not the GCP project id."
}

variable "alethia_environment" {
  type        = string
  default     = ""
  description = "Injected by the Alethia runner as TF_VAR_alethia_environment."
}

variable "drift_marker" {
  type        = string
  default     = "baseline"
  description = <<-EOT
    The single value this module OWNS. Leave it at the default: the drift step overwrites the
    metadata value OUT OF BAND (gcloud compute project-info add-metadata), which is what a
    refresh-only plan must then report. Changing it here would be an ordinary tofu change.
  EOT
}

variable "name_suffix" {
  type        = string
  default     = ""
  description = "Optional disambiguator when several tenants share one GCP project."
}

locals {
  project     = trimspace(var.alethia_project) != "" ? trimspace(var.alethia_project) : "unset"
  environment = trimspace(var.alethia_environment) != "" ? trimspace(var.alethia_environment) : "unset"
  suffix      = trimspace(var.name_suffix) != "" ? "-${trimspace(var.name_suffix)}" : ""

  # Metadata keys accept letters, digits, dash and underscore only.
  slug = lower(replace("${local.project}-${local.environment}${local.suffix}", "/[^a-zA-Z0-9-]/", "-"))
}

# A single project-metadata item: free, project-scoped (no global name collisions, unlike a
# storage bucket), and mutable by a one-line CLI call. `google_compute_project_metadata_item`
# manages ONE key in isolation — it does not rewrite the whole project metadata map, so it
# cannot clobber a key it does not own.
resource "google_compute_project_metadata_item" "drift" {
  key   = "alethia-byo-drift-${local.slug}"
  value = var.drift_marker
}

output "drift_marker" {
  value       = google_compute_project_metadata_item.drift.value
  description = "The value tofu believes it owns. After an out-of-band mutation this no longer matches reality, and DETECT_DRIFT says so."
}

output "drift_target" {
  value       = google_compute_project_metadata_item.drift.key
  description = "What to mutate to induce drift. See the README for the exact command."
}

output "alethia_context" {
  value       = "${local.project}/${local.environment}"
  description = "Proves the runner's TF_VAR_alethia_* injection reached the module."
}
