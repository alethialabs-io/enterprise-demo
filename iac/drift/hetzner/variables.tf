# ── The frozen context Alethia injects. ──
#
# The runner publishes these as TF_VAR_alethia_* before `tofu init` (packages/core/provisioner/
# byo_iac.go). They are declared here with defaults so the module still plans standalone — but the
# `alethia_context` output is what proves the injection actually reached it: a run that fell back to
# these defaults produces "local/dev", which is not the project/environment the harness expects.
variable "alethia_project" {
  description = "Alethia project name, injected as TF_VAR_alethia_project."
  type        = string
  default     = "local"
}

variable "alethia_environment" {
  description = "Alethia environment stage, injected as TF_VAR_alethia_environment."
  type        = string
  default     = "dev"
}

variable "alethia_region" {
  description = "Primary region, injected as TF_VAR_alethia_region."
  type        = string
  default     = ""
}

variable "alethia_project_id" {
  description = "Alethia configuration id, injected as TF_VAR_alethia_project_id."
  type        = string
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "alethia_environment_id" {
  description = "Alethia environment id, injected as TF_VAR_alethia_environment_id."
  type        = string
  default     = "00000000-0000-0000-0000-000000000000"
}

# ── The drift probe. ──
#
# Exactly one mutable value on exactly one resource. An out-of-band CLI moves the LIVE value away
# from this default; DETECT_DRIFT must then report drifted, and a heal apply must put it back.
#
# Changing this variable and re-applying would be an ordinary configuration change and would prove
# nothing about detecting an out-of-band one — which is why the harness mutates the cloud directly
# and leaves the module untouched.
variable "drift_marker" {
  description = "Baseline value of the drift probe. The harness mutates the LIVE value, never this."
  type        = string
  default     = "baseline"
}

# A short, stable, per-environment suffix. Cloud resource names have length budgets and charset
# rules, so the full uuid is never used directly.
locals {
  suffix = substr(replace(var.alethia_environment_id, "-", ""), 0, 8)
  name   = "alethia-byo-${local.suffix}"
}
