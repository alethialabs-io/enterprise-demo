# Alethia BYO-IaC gate fixture — THIS MODULE IS MEANT TO BE REFUSED.
#
# It is never applied and provisions nothing. It exists so an Alethia end-to-end leg can
# prove that the fail-closed `iacsafety` gate has TEETH: point a deploy at this path and
# the job must FAIL with a provider-not-allowlisted finding, BEFORE `tofu init` downloads
# anything and BEFORE any plan or apply.
#
# Without a negative case the gate assertion is vacuous — a gate that passes everything
# looks exactly like a gate that works, and "the deploy succeeded" is not evidence that
# anything was checked.
#
# `tehcyx/kind` is deliberately chosen: it is a real provider, it is NOT on Alethia's
# DefaultProviderAllowlist, and it is the same provider Alethia's own hermetic BYO test
# uses as its blocked example. Do not add it to the allowlist to "fix" this directory.

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = ">= 0.2"
    }
  }
}

variable "alethia_project" {
  type        = string
  default     = ""
  description = "Injected by the Alethia runner as TF_VAR_alethia_project. Never read — the gate blocks first."
}

variable "alethia_environment" {
  type        = string
  default     = ""
  description = "Injected by the Alethia runner as TF_VAR_alethia_environment. Never read — the gate blocks first."
}

# Never created: the static gate refuses the module before init resolves this provider.
resource "kind_cluster" "never" {
  name = "alethia-byo-gate-fixture"
}
