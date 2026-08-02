# Alethia BYO-IaC drift probe — Azure.
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
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

# Credentials are ambient: ActivateAzureFederated sets ARM_USE_OIDC, ARM_CLIENT_ID,
# ARM_TENANT_ID, ARM_SUBSCRIPTION_ID and ARM_OIDC_TOKEN_FILE_PATH before dispatch, so this
# authenticates keylessly with no secret in the module or the repo.
provider "azurerm" {
  features {}
}

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
    tag OUT OF BAND (az group update --set tags.drift_marker=...), which is what a refresh-only
    plan must then report. Changing it here would be an ordinary tofu change and prove nothing.
  EOT
}

variable "location" {
  type        = string
  default     = "westeurope"
  description = "Where the (empty, free) resource group lives."
}

variable "name_suffix" {
  type        = string
  default     = ""
  description = "Optional disambiguator when several tenants share one subscription."
}

locals {
  project     = trimspace(var.alethia_project) != "" ? trimspace(var.alethia_project) : "unset"
  environment = trimspace(var.alethia_environment) != "" ? trimspace(var.alethia_environment) : "unset"
  suffix      = trimspace(var.name_suffix) != "" ? "-${trimspace(var.name_suffix)}" : ""

  # Resource-group names allow letters, digits, dot, dash, underscore and parens; slug
  # anything else out so an arbitrary project name cannot produce an invalid name.
  slug = lower(replace("${local.project}-${local.environment}${local.suffix}", "/[^a-zA-Z0-9-]/", "-"))
}

# An EMPTY resource group: free, subscription-scoped, and its tags are mutable by a one-line
# CLI call. Nothing is placed inside it — the group itself is the whole probe.
resource "azurerm_resource_group" "drift" {
  name     = "alethia-byo-drift-${local.slug}"
  location = var.location

  tags = {
    alethia_project     = local.project
    alethia_environment = local.environment
    alethia_purpose     = "byo-iac-drift-probe"
    drift_marker        = var.drift_marker
  }
}

output "drift_marker" {
  value       = azurerm_resource_group.drift.tags["drift_marker"]
  description = "The value tofu believes it owns. After an out-of-band mutation this no longer matches reality, and DETECT_DRIFT says so."
}

output "drift_target" {
  value       = azurerm_resource_group.drift.name
  description = "What to mutate to induce drift. See the README for the exact command."
}

output "alethia_context" {
  value       = "${local.project}/${local.environment}"
  description = "Proves the runner's TF_VAR_alethia_* injection reached the module."
}
