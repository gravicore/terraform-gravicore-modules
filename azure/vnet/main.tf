# ----------------------------------------------------------------------------------------------------------------------
# VNET resource
# ----------------------------------------------------------------------------------------------------------------------

resource "azurerm_virtual_network" "vnet" {
  count                   = var.create ? 1 : 0
  name                    = var.name
  location                = var.az_location
  resource_group_name     = var.resource_group_name
  tags                    = var.tags
  bgp_community           = var.bgp_community == null ? null : join(":", ["12076", var.bgp_community])
  address_space           = var.vnet_cidr_block
  dns_servers             = var.dns_servers
  edge_zone               = var.edge_zone
  flow_timeout_in_minutes = var.flow_timeout_in_minutes
}

# ----------------------------------------------------------------------------------------------------------------------
# Subnet resource
# ----------------------------------------------------------------------------------------------------------------------

resource "azurerm_subnet" "subnet" {
  for_each                                      = var.subnet_details

  name                                          = each.value.name
  resource_group_name                           = var.resource_group_name
  virtual_network_name                          = azurerm_virtual_network.vnet[0].name
  address_prefixes                              = each.value.address_prefixes
  service_endpoints                             = each.value.service_endpoints
  private_endpoint_network_policies_enabled     = lookup(each.value, "private_endpoint_network_policies_enabled", true)
  private_link_service_network_policies_enabled = lookup(each.value, "private_link_service_network_policies_enabled", true)
  tags = local.tags

  dynamic "delegation" {
    for_each = each.value.service_delegation ? [1] : []
    content {
      name = each.value.delegation_details.name
      service_delegation {
        name    = each.value.delegation_details.name
        actions = each.value.delegation_details.actions
      }
    }
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# Subnet Network security group resource
# ----------------------------------------------------------------------------------------------------------------------

resource "azurerm_network_security_group" "subnet_nsg" {
  for_each            = var.subnet_nsg_details

  name                = each.value.name
  resource_group_name = var.resource_group_name
  location            = var.az_location
  tags = local.tags

  dynamic "security_rule" {
    for_each = try(each.value.security_rules, [])

    content {
      name                                       = try(security_rule.value.name, null)
      priority                                   = try(security_rule.value.priority, null)
      direction                                  = try(security_rule.value.direction, null)
      access                                     = try(security_rule.value.access, null)
      protocol                                   = try(security_rule.value.protocol, null)
      source_port_range                          = try(security_rule.value.source_port_range, null)
      source_port_ranges                         = try(security_rule.value.source_port_ranges, null)
      destination_port_range                     = try(security_rule.value.destination_port_range, null)
      destination_port_ranges                    = try(security_rule.value.destination_port_ranges, null)
      source_address_prefix                      = try(security_rule.value.source_address_prefix, null)
      source_address_prefixes                    = try(security_rule.value.source_address_prefixes, null)
      destination_address_prefix                 = try(security_rule.value.destination_address_prefix, null)
      destination_address_prefixes               = try(security_rule.value.destination_address_prefixes, null)
      source_application_security_group_ids      = try(security_rule.value.source_application_security_group_ids, null)
      destination_application_security_group_ids = try(security_rule.value.destination_application_security_group_ids, null)
    }
  }
}


# ----------------------------------------------------------------------------------------------------------------------
# Subnet to NSG association
# ----------------------------------------------------------------------------------------------------------------------
resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
  for_each                  = var.subnet_nsg_details

  subnet_id                 = azurerm_subnet.subnet[each.key].id
  network_security_group_id = azurerm_network_security_group.subnet_nsg[each.key].id
}
