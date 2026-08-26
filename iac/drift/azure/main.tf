terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# THE PROBE. An empty resource group is free and carries mutable tags, which is what
# `az group update --set tags.drift_marker=<value>` changes out of band.
#
# `location` comes from the injected region rather than a literal: a customer module that hardcoded
# a region would provision somewhere the rest of the environment is not.
resource "azurerm_resource_group" "drift_probe" {
  name     = local.name
  location = var.alethia_region != "" ? var.alethia_region : "westeurope"

  tags = {
    drift_marker = var.drift_marker
    managed_by   = "alethia-byo-iac-e2e"
  }
}
