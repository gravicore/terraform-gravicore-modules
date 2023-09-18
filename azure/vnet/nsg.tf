
# ----------------------------------------------------------------------------------------------------------------------
# Subnet Network security group resource
# ----------------------------------------------------------------------------------------------------------------------

resource "azurerm_network_security_group" "default" {
  for_each            = var.create && length(local.subnets_with_nsg_rules) > 0 ? local.subnets_with_nsg_rules : {}
  name                = join(var.delimiter, [azurerm_subnet.default[each.key].name, "nsg"])
  resource_group_name = var.resource_group_name
  location            = var.az_region
  tags                = local.tags

  dynamic "security_rule" {
    for_each = try(each.value.nsg_rules.custom_security_rules, [])

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

  dynamic "security_rule" {
    for_each = toset(each.value.nsg_rules.deny_all_inbound == true ? ["enabled"] : [])

    content {
      name                       = "deny-all-inbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }

  dynamic "security_rule" {
    for_each = toset(each.value.nsg_rules.http_inbound_allowed == true ? ["enabled"] : [])

    content {
      name                       = "http-inbound"
      priority                   = 4000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = try(tostring(each.value.nsg_rules.allowed_http_source), null)
      source_address_prefixes    = try(tolist(each.value.nsg_rules.allowed_http_source), null)
      destination_address_prefix = "VirtualNetwork"
    }
  }
  dynamic "security_rule" {
    for_each = toset(each.value.nsg_rules.https_inbound_allowed == true ? ["enabled"] : [])

    content {
      name                       = "https-inbound"
      priority                   = 4001
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = try(tostring(each.value.nsg_rules.allowed_https_source), null)
      source_address_prefixes    = try(tolist(each.value.nsg_rules.allowed_https_source), null)
      destination_address_prefix = "VirtualNetwork"
    }
  }
  dynamic "security_rule" {
    for_each = toset(each.value.nsg_rules.ssh_inbound_allowed == true ? ["enabled"] : [])

    content {
      name                       = "ssh-inbound"
      priority                   = 4002
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = try(tostring(each.value.nsg_rules.allowed_ssh_source), null)
      source_address_prefixes    = try(tolist(each.value.nsg_rules.allowed_ssh_source), null)
      destination_address_prefix = "VirtualNetwork"
    }
  }
  dynamic "security_rule" {
    for_each = toset(each.value.nsg_rules.rdp_inbound_allowed == true ? ["enabled"] : [])

    content {
      name                       = "rdp-inbound"
      priority                   = 4003
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3389"
      source_address_prefix      = try(tostring(each.value.nsg_rules.allowed_rdp_source), null)
      source_address_prefixes    = try(tolist(each.value.nsg_rules.allowed_rdp_source), null)
      destination_address_prefix = "VirtualNetwork"
    }
  }
  dynamic "security_rule" {
    for_each = toset(each.value.nsg_rules.winrm_inbound_allowed == true ? ["enabled"] : [])

    content {
      name                       = "winrm-inbound"
      priority                   = 4004
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "5986"
      source_address_prefix      = try(tostring(each.value.nsg_rules.allowed_winrm_source), null)
      source_address_prefixes    = try(tolist(each.value.nsg_rules.allowed_winrm_source), null)
      destination_address_prefix = "VirtualNetwork"
    }
  }

  dynamic "security_rule" {
    for_each = toset(each.value.nsg_rules.application_gateway_rules_enabled == true ? ["enabled"] : [])

    content {
      name                       = "appgw-health-probe-inbound"
      priority                   = 4005
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "65200-65535"
      source_address_prefix      = "GatewayManager"
      destination_address_prefix = "VirtualNetwork"
    }
  }
  dynamic "security_rule" {
    for_each = toset(each.value.nsg_rules.application_gateway_rules_enabled || each.value.nsg_rules.load_balancer_rules_enabled ? ["enabled"] : [])

    content {
      name                       = "lb-health-probe-inbound"
      priority                   = 4006
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "65200-65535"
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "VirtualNetwork"
    }

  }
  dynamic "security_rule" {
    for_each = toset(each.value.nsg_rules.nfs_inbound_allowed == true ? ["enabled"] : [])

    content {
      name                       = "nfs-inbound"
      priority                   = 4007
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "2049"
      source_address_prefix      = try(tostring(each.value.nsg_rules.allowed_nfs_source), null)
      source_address_prefixes    = try(tolist(each.value.nsg_rules.allowed_nfs_source), null)
      destination_address_prefix = "VirtualNetwork"
    }
  }

  dynamic "security_rule" {
    for_each = toset(each.value.nsg_rules.cifs_inbound_allowed == true ? ["enabled"] : [])

    content {
      name                       = "cifs-inbound"
      priority                   = 4008
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = ["137", "138", "139", "445"]
      source_address_prefix      = try(tostring(each.value.nsg_rules.allowed_cifs_source), null)
      source_address_prefixes    = try(tolist(each.value.nsg_rules.allowed_cifs_source), null)
      destination_address_prefix = "VirtualNetwork"
    }
  }
}


# ----------------------------------------------------------------------------------------------------------------------
# Subnet to NSG association
# ----------------------------------------------------------------------------------------------------------------------
resource "azurerm_subnet_network_security_group_association" "default" {
  for_each                  = var.create ? local.subnets_map : {}
  subnet_id                 = azurerm_subnet.default[each.key].id
  network_security_group_id = azurerm_network_security_group.default[each.key].id
}

