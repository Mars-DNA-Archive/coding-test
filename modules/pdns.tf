locals {
  dns_resources = {
    for k, v in try(var.foundation.dns_resources, {}) : k => merge(
      {
        # overrideable defaults
        resource_group_name = local.default_resource_group.name
      },
      v
    )
  }
}

output "dns_resources_output" {
  value = local.dns_resources
}

# create dns zone resource
resource "azurerm_private_dns_zone" "pdns" {
  for_each            = local.dns_resources
  name                = each.key
  resource_group_name = each.value.resource_group_name

  depends_on = [ 
    azurerm_resource_group.resource_group
   ]
}

# create link to vnet
resource "azurerm_private_dns_zone_virtual_network_link" "pdnsl_hub" {
  for_each              = local.dns_resources
  name                  = "vnet-link"
  resource_group_name   = each.value.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.pdns["${each.key}"].name
  virtual_network_id    = azurerm_virtual_network.networks["${each.value.vnet_name}"].id
}