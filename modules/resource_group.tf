#Create local variable
locals {
  resource_groups = {
    for v in var.foundation.resource_groups : v.name => v
  }
 default_resource_group = [
    for k, v in local.resource_groups : {
      name     = k
      location = v.location
    } if v.is_default
  ][0]
}

# create new resource groups
resource "azurerm_resource_group" "resource_group" {
  for_each = local.resource_groups

  name     = each.value.name
  location = each.value.location
}

# look the existing (or newly created) resource group to use as a reference for all
# other resource creations
data "azurerm_resource_group" "resource_group" {
  for_each = local.resource_groups
  name     = each.value.name

  depends_on = [azurerm_resource_group.resource_group]
}
