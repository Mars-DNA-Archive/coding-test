# Terraform backend configuration for remote state file
terraform {
  backend "local" {

  }
  
}

# defintion of the Azure provider version
provider "azurerm" {
  features {}
}

variable "foundation" {}

module "foundation" {
  source = "./modules"

  foundation = var.foundation

  providers = {
    azurerm.remote = azurerm
  }
}

output "test" {
  value = module.foundation
}