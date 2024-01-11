# virutal_networks
locals {
  networks = {
    for k, v in try(var.foundation.networks, {}) : k => merge(
      {
        # overrideable defaults
        subnets              = {}
        location             = local.default_resource_group.location
        resource_group_name  = local.default_resource_group.name
        dns_servers          = []
      },
      v
    )
  }

  subnets = {
    for entry in flatten([
      for network_key, network_data in local.networks : [
        for subnet_key, subnet_data in network_data.subnets :
        merge(
          {
            network                                        = network_key
            subnet                                         = subnet_key
            service_endpoints                              = subnet_data.service_endpoints
            delegations                                    = subnet_data.delegations
            enable_nat_gateway                             = false
            enforce_private_link_endpoint_network_policies = true
            enforce_private_link_service_network_policies  = true
          },
          subnet_data,
          {
            resource_group_name  = azurerm_virtual_network.networks[network_key].resource_group_name
            virtual_network_name = azurerm_virtual_network.networks[network_key].name
          }
        )
      ]
    ]) : "${entry.network}-${entry.subnet}" => entry
  }
}

# create virtual networks
resource "azurerm_virtual_network" "networks" {
  for_each = local.networks
  
  name                = each.key
  location            = each.value.location
  resource_group_name = data.azurerm_resource_group.resource_group[each.value.resource_group_name].name
  address_space       = each.value.address_space
  dns_servers         = each.value.dns_servers
}

# create the subnets
resource "azurerm_subnet" "networks" {
  for_each = local.subnets

  resource_group_name  = data.azurerm_resource_group.resource_group[each.value.resource_group_name].name
  virtual_network_name = each.value.virtual_network_name
  name                 = each.value.subnet
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = each.value.service_endpoints

  private_endpoint_network_policies_enabled     = each.value.enforce_private_link_endpoint_network_policies
  private_link_service_network_policies_enabled = each.value.enforce_private_link_service_network_policies

  dynamic "delegation" {
    for_each = each.value.delegations
    content {
      name = delegation.value.service_delegation.name
      service_delegation {
        actions = delegation.value.service_delegation.actions
        name    = delegation.value.service_delegation.name
      }
    }
  }
}