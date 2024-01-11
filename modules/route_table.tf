# Route Tables
locals {
  route_tables = {
    for k, v in try(var.foundation.route_tables, {}) : k => merge(
      {
        # overrideable defaults
        location            = local.default_resource_group.location
        resource_group_name = local.default_resource_group.name
      },
      v,
      {
        # fixed values and references
        disable_bgp_route_propagation = false
        next_hop_type = "VirtualNetworkGateway"
      }
    )
  }
  
  subnet_route_table_associations = {
    for entry in flatten([
      for k, v in local.route_tables : [
        for subnet_association in v.subnet_associations : [
          for subnet in subnet_association.subnets : {
            key            = "${subnet_association.network}-${subnet}"
            subnet_id      = azurerm_subnet.networks["${subnet_association.network}-${subnet}"].id
            route_table_id = azurerm_route_table.route_tables[k].id
          }
        ]
      ]
    ]) : entry.key => entry
  }
}

# create required route tables
resource "azurerm_route_table" "route_tables" {
  for_each = local.route_tables

  name                          = each.key
  location                      = each.value.location
  resource_group_name           = data.azurerm_resource_group.resource_group[each.value.resource_group_name].name
  disable_bgp_route_propagation = each.value.disable_bgp_route_propagation

  dynamic "route" {
    for_each = each.value.routes
    content {
      name                   = route.key
      address_prefix         = route.value.address_prefix
      next_hop_type          = try(route.value.next_hop_type, each.value.next_hop_type)
      next_hop_in_ip_address = try(route.value.next_hop_in_ip_address, null)
    }
  }

}

# create the associations
resource "azurerm_subnet_route_table_association" "route_tables" {
  for_each = local.subnet_route_table_associations

  subnet_id      = each.value.subnet_id
  route_table_id = each.value.route_table_id
}
