# Alethia BYO-IaC drift probe — AWS.
#
# The customer's OWN OpenTofu module, from the customer's OWN repo, applied by Alethia's
# runner under the runner's federated cloud identity. It exists to prove ONE claim end to
# end: that Alethia keeps re-proving your infrastructure after the first apply, and that a
# change made OUTSIDE Alethia is detected.
#
# The loop it proves:
#
#   clone at a pinned SHA  →  fail-closed iacsafety gate  →  plan  →  signed verify receipt
#   →  apply  →  state held on Alethia's proxy (never by you)  →  … later …
#   mutate `drift_marker` OUT OF BAND (see README)  →  refresh-only DETECT_DRIFT  →  DRIFTED
#
# Two deliberate omissions, both load-bearing:
#
#   * NO `backend` block. The runner injects an HTTP state-proxy override at init. A backend
#     here would fight it, and the whole point is that Alethia holds the state, not you.
#   * NO `cluster_name` output. That output is what makes the runner continue into the
#     kubeconfig → CNI → ArgoCD tail. Without it the run stops after state-to-proxy, so this
#     module provisions NO cluster and costs nothing to speak of.

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# Region and credentials both arrive as ambient process environment: the runner's
# ActivateAwsFederated sets AWS_CONFIG_FILE / AWS_PROFILE / AWS_SDK_LOAD_CONFIG / AWS_REGION
# for a web-identity (keyless) profile before the job is dispatched. No static keys exist to
# leak, and none are accepted inside the container sandbox.
provider "aws" {}

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
    parameter OUT OF BAND (aws ssm put-parameter --overwrite), which is precisely what a
    refresh-only plan must then report as drift. Changing it here instead would be an ordinary
    tofu change and would prove nothing.
  EOT
}

variable "name_suffix" {
  type        = string
  default     = ""
  description = "Optional disambiguator when several tenants share one account."
}

locals {
  project     = trimspace(var.alethia_project) != "" ? trimspace(var.alethia_project) : "unset"
  environment = trimspace(var.alethia_environment) != "" ? trimspace(var.alethia_environment) : "unset"
  suffix      = trimspace(var.name_suffix) != "" ? "-${trimspace(var.name_suffix)}" : ""

  # SSM parameter names accept slashes, so the natural hierarchy needs no slugging.
  parameter_name = "/alethia/byo-iac-drift/${local.project}/${local.environment}${local.suffix}"
}

# A Standard-tier SSM parameter: free, account-scoped (no global name collisions), and
# mutable by a one-line CLI call — the cheapest thing on AWS that can genuinely drift.
resource "aws_ssm_parameter" "drift" {
  name        = local.parameter_name
  description = "Alethia BYO-IaC drift probe. Safe to delete."
  type        = "String"
  tier        = "Standard"

  # `insecure_value`, not `value`, and deliberately so. `value` is a SENSITIVE attribute, so
  # exporting it would force `sensitive = true` on the output and redact the one thing a drift
  # leg needs to read. `insecure_value` is the provider's supported plaintext form for a
  # non-SecureString parameter — which is exactly what a drift marker is. It is not a secret,
  # and it should not pretend to be one.
  insecure_value = var.drift_marker

  tags = {
    "alethia:project"     = local.project
    "alethia:environment" = local.environment
    "alethia:purpose"     = "byo-iac-drift-probe"
  }
}

output "drift_marker" {
  value       = aws_ssm_parameter.drift.insecure_value
  description = "The value tofu believes it owns. After an out-of-band mutation this no longer matches reality, and DETECT_DRIFT says so."
}

output "drift_target" {
  value       = aws_ssm_parameter.drift.name
  description = "What to mutate to induce drift. See the README for the exact command."
}

output "alethia_context" {
  value       = "${local.project}/${local.environment}"
  description = "Proves the runner's TF_VAR_alethia_* injection reached the module."
}
