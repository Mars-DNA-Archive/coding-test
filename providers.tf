terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = ">= 3.76.0"
      configuration_aliases = [azurerm.remote]
    }
  }
}

data "azurerm_client_config" "current" {}