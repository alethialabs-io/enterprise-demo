terraform {
  required_version = ">= 1.6.0"
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~> 1.220"
    }
  }
}

# THE PROBE. An empty OSS bucket costs nothing to hold and carries mutable tags, which is what
# `aliyun oss bucket-tagging --method put` changes out of band.
#
# `force_destroy` because the harness's own teardown must not be able to leave a bucket standing:
# a probe that survives destroy becomes an orphan the reaper then has to chase.
resource "alicloud_oss_bucket" "drift_probe" {
  bucket        = local.name
  force_destroy = true

  tags = {
    drift_marker = var.drift_marker
    managed_by   = "alethia-byo-iac-e2e"
  }
}
