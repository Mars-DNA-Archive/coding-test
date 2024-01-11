locals {
  central_akv = {
    for k, v in try(var.foundation.central_akv, {}) : v.key_vault_name => merge(
      {
        # overrideable defaults
        resource_group_name = local.default_resource_group.name
        location            = local.default_resource_group.location
        tenant_id           = "2fc13e34-f03f-498b-982a-7cb446e25bc6"
        dns_rg_name         = "CODING-CHALLENGE-EUS2-RG"
        akv_snet_name       = "akvpesnet-001"
      },
      v
    )
  }
}

data "azurerm_virtual_network" "vnet" {
  for_each            = local.central_akv
  name                = each.value.virtual_network_name
  resource_group_name = each.value.vnet_resource_group_name
  depends_on          = [azurerm_virtual_network.networks]
}

data "azurerm_subnet" "akv_subnet" {
  for_each             = local.central_akv
  name                 = each.value.akv_snet_name
  resource_group_name  = each.value.vnet_resource_group_name
  virtual_network_name = data.azurerm_virtual_network.vnet[each.key].name

  depends_on = [azurerm_subnet.networks]
}

resource "azurerm_key_vault" "datalib_key_vault" {
  # TODO: Challenge 3 finish the module with changing the code here to create keyvaults by looping
  # through the local block above
  
}

data "azurerm_private_dns_zone" "dns_zone" {
  for_each            = local.central_akv
  provider            = azurerm.remote
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = each.value.dns_rg_name

  depends_on = [ 
    azurerm_private_dns_zone.pdns
   ]
}

resource "azurerm_private_endpoint" "pe1" {
  for_each            = local.central_akv
  name                = "${each.value.key_vault_name}pe"
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  subnet_id           = data.azurerm_subnet.akv_subnet[each.key].id
  private_service_connection {
    name                           = "${each.value.key_vault_name}psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_key_vault.datalib_key_vault[each.key].id
    subresource_names              = ["vault"]
  }
  private_dns_zone_group {
    name                 = data.azurerm_private_dns_zone.dns_zone[each.key].name
    private_dns_zone_ids = [data.azurerm_private_dns_zone.dns_zone[each.key].id]
  }
}