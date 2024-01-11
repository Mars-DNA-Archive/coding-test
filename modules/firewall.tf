# Firewalls
locals {
  # handle optional parameters for firewalls
  firewalls = {
    for k, v in try(var.foundation.firewalls, {}) : k => merge(
      {
        # overrideable defaults
        application_rule_collections = {}
        nat_rule_collections         = {}
        network_rule_collections     = {}
        location                     = local.default_resource_group.location
        resource_group_name          = local.default_resource_group.name
        sku_name                     = "AZFW_VNet"
        dns_servers                  = []
      },
      v,
      {
        # references and fixed values
        subnet_id         = azurerm_subnet.networks["${v.network}-AzureFirewallSubnet"].id
        nic_name          = "${k}-pip"
        ip_config_name    = "${k}-AzureFirewallSubnet"
        allocation_method = "Static"
        sku               = "Premium"
      }
    )
  }
}

# create public ip address for each firewall
resource "azurerm_public_ip" "firewalls" {
  for_each = local.firewalls

  name                = each.value.nic_name
  location            = each.value.location
  resource_group_name = data.azurerm_resource_group.resource_group[each.value.resource_group_name].name
  allocation_method   = each.value.allocation_method
  sku                 = "Standard"
}

# create each firewall
resource "azurerm_firewall" "firewalls" {
  for_each = local.firewalls

  name                = each.key
  location            = each.value.location
  resource_group_name = data.azurerm_resource_group.resource_group[each.value.resource_group_name].name
  sku_tier            = each.value.sku
  sku_name            = each.value.sku_name
  firewall_policy_id  = azurerm_firewall_policy.parent[each.key].id

  dynamic "ip_configuration" {
    for_each =  local.firewalls
    content {
      name                 = each.value.ip_config_name
      subnet_id            = each.value.subnet_id
      public_ip_address_id = azurerm_public_ip.firewalls[each.key].id
    }
  }

  # avoids race condition in Azure provisioning
  depends_on = [
    azurerm_subnet_route_table_association.route_tables,
    azurerm_firewall_policy.parent
  ]
}

# Data block for lookup firewalls
data "azurerm_firewall" "firewalls" {
  for_each = local.firewalls

  name                = each.key
  resource_group_name = each.value.resource_group_name

  depends_on = [azurerm_firewall.firewalls]
}



resource "azurerm_firewall_policy" "parent" {
  for_each                 = local.firewalls
  name                     = "${each.key}-parent-policy"
  resource_group_name      = each.value.resource_group_name
  location                 = each.value.location
  sku                      = "Premium"
  threat_intelligence_mode = "Alert"


  dns {
    proxy_enabled = true
    servers       = []
  }

  intrusion_detection {
    mode = "Alert"
  }
  
}

# Local block for Network rules
locals{
network_rules = {
    for entry in flatten([
      for firewall_key, firewall_data in local.firewalls : [
        for rule_key, rule_data in firewall_data.network_rule_collections :
        merge(
          {
            rule_name = rule_key
            resource_group_name = local.default_resource_group.name
            firewall_name = firewall_key
          },
          rule_data
        )
      ]
    ]) : "${entry.firewall_name}-${entry.rule_name}" => entry
  }
}

# Resouce Block for Network Rules
resource "azurerm_firewall_policy_rule_collection_group" "network" {
  for_each           = local.firewalls
  name               = "fwpolicy-rcg"
  firewall_policy_id = azurerm_firewall_policy.parent[each.key].id
  priority           = 100

  network_rule_collection {
    name     = "network_rule_collection1"
    priority = 400
    action   = "Allow"
    dynamic "rule" {
      for_each = local.network_rules
      content {
        name                  = rule.value["rule_name"]
        protocols             = rule.value["protocols"]
        source_addresses      = rule.value["source_addresses"]
        destination_addresses = try(rule.value["destination_addresses"], null)
        destination_fqdns     = try(rule.value["destination_fqdns"], null)
        destination_ports     = rule.value["destination_ports"]
      }
    }
  }
}
