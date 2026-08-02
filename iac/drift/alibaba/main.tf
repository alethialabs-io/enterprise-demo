# Alethia BYO-IaC drift probe — Alibaba Cloud.
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
    alicloud = {
      # Matches the source the first-party Alethia alibaba template pins, so the
      # iacsafety provider allowlist resolves identically for both.
      source  = "aliyun/alicloud"
      version = ">= 1.230, < 2.0"
    }
  }
}

# Credentials are ambient: ActivateAlibabaOIDC sets ALIBABA_CLOUD_ROLE_ARN,
# ALIBABA_CLOUD_OIDC_PROVIDER_ARN and ALIBABA_CLOUD_OIDC_TOKEN_FILE before dispatch, and the
# provider performs its own AssumeRoleWithOIDC from that token file. Keyless — no access-key
# pair exists in this repo or in the runner's environment.
provider "alicloud" {}

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
    bucket tag OUT OF BAND (aliyun oss bucket-tagging), which is what a refresh-only plan must
    then report. Changing it here would be an ordinary tofu change and prove nothing.
  EOT
}

variable "name_suffix" {
  type        = string
  default     = ""
  description = <<-EOT
    Optional disambiguator. OSS bucket names are GLOBALLY unique, so if two tenants would derive
    the same project-environment slug, set this to keep them apart.
  EOT
}

locals {
  project     = trimspace(var.alethia_project) != "" ? trimspace(var.alethia_project) : "unset"
  environment = trimspace(var.alethia_environment) != "" ? trimspace(var.alethia_environment) : "unset"
  suffix      = trimspace(var.name_suffix) != "" ? "-${trimspace(var.name_suffix)}" : ""

  # OSS bucket names: lowercase letters, digits and dashes; 3–63 chars; no leading or
  # trailing dash. Slug first, then trim, so an arbitrary project name cannot produce an
  # invalid name.
  raw  = lower(replace("alethia-byo-drift-${local.project}-${local.environment}${local.suffix}", "/[^a-z0-9-]/", "-"))
  name = trim(substr(local.raw, 0, 63), "-")
}

# An EMPTY OSS bucket: storage is billed by what you put in it, and nothing is ever put in
# it, so this costs nothing in practice. Its tags are mutable by a one-line CLI call.
resource "alicloud_oss_bucket" "drift" {
  bucket = local.name

  tags = {
    alethia_project     = local.project
    alethia_environment = local.environment
    alethia_purpose     = "byo-iac-drift-probe"
    drift_marker        = var.drift_marker
  }
}

output "drift_marker" {
  value       = alicloud_oss_bucket.drift.tags["drift_marker"]
  description = "The value tofu believes it owns. After an out-of-band mutation this no longer matches reality, and DETECT_DRIFT says so."
}

output "drift_target" {
  value       = alicloud_oss_bucket.drift.bucket
  description = "What to mutate to induce drift. See the README for the exact command."
}

output "alethia_context" {
  value       = "${local.project}/${local.environment}"
  description = "Proves the runner's TF_VAR_alethia_* injection reached the module."
}
