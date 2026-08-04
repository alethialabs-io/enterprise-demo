# Alethia BYO-IaC drift probe — Hetzner Cloud.
#
# See ../README.md for the full contract. In short: this is the customer's OWN module,
# applied by Alethia's runner under its own credentials, whose only job is to own one
# mutable value so that a change made OUTSIDE Alethia can be detected by a later
# refresh-only DETECT_DRIFT.
#
# NO `backend` block (the runner injects the HTTP state-proxy override) and NO
# `cluster_name` output (that output is what would make the runner continue into the
# kubeconfig → CNI → ArgoCD tail; without it the run stops after state-to-proxy).

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.45"
    }
  }
}

# Credentials are ambient: the runner exports HCLOUD_TOKEN before dispatch and the
# provider reads it from the environment. Hetzner has no federation, so this is the one
# cloud where the credential is a token rather than an OIDC exchange — the module itself
# still holds nothing.
provider "hcloud" {}

variable "alethia_project" {
  type        = string
  default     = ""
  description = "Injected by the Alethia runner as TF_VAR_alethia_project."
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
    label OUT OF BAND (hcloud placement-group add-label --overwrite), which is what a
    refresh-only plan must then report. Changing it here would be an ordinary tofu change and
    would prove nothing.
  EOT
}

variable "name_suffix" {
  type        = string
  default     = ""
  description = "Optional disambiguator when several tenants share one Hetzner project."
}

locals {
  project     = trimspace(var.alethia_project) != "" ? trimspace(var.alethia_project) : "unset"
  environment = trimspace(var.alethia_environment) != "" ? trimspace(var.alethia_environment) : "unset"
  suffix      = trimspace(var.name_suffix) != "" ? "-${trimspace(var.name_suffix)}" : ""

  # Placement-group names allow letters, digits, dash, underscore and dot; slug anything
  # else out so an arbitrary project name cannot produce an invalid name.
  raw  = lower(replace("alethia-byo-drift-${local.project}-${local.environment}${local.suffix}", "/[^a-z0-9-]/", "-"))
  name = trim(substr(local.raw, 0, 63), "-")
}

# An EMPTY placement group: free (it is a scheduling constraint, not a resource — no
# server is ever placed in it), project-scoped, and its labels are mutable by a one-line
# CLI call. Hetzner has no tagging API and no free key-value store, so a labelled
# placement group is the cheapest thing here that can genuinely drift.
resource "hcloud_placement_group" "drift" {
  name = local.name
  type = "spread"

  labels = {
    alethia_project     = local.project
    alethia_environment = local.environment
    alethia_purpose     = "byo-iac-drift-probe"
    drift_marker        = var.drift_marker
  }
}

output "drift_marker" {
  value       = hcloud_placement_group.drift.labels["drift_marker"]
  description = "The value tofu believes it owns. After an out-of-band mutation this no longer matches reality, and DETECT_DRIFT says so."
}

output "drift_target" {
  value       = hcloud_placement_group.drift.name
  description = "What to mutate to induce drift. See the README for the exact command."
}

output "alethia_context" {
  value       = "${local.project}/${local.environment}"
  description = "Proves the runner's TF_VAR_alethia_* injection reached the module."
}
