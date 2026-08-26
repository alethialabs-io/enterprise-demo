terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# THE PROBE. An SSM parameter is free, region-local, and its value is a single mutable string —
# which is exactly what an out-of-band `aws ssm put-parameter --overwrite` changes.
resource "aws_ssm_parameter" "drift_probe" {
  name  = "/alethia/byo-iac/${local.suffix}/drift_marker"
  type  = "String"
  value = var.drift_marker

  tags = {
    managed_by = "alethia-byo-iac-e2e"
  }
}
