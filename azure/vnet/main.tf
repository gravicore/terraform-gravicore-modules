# ----------------------------------------------------------------------------------------------------------------------
# CAF resource
# ----------------------------------------------------------------------------------------------------------------------

module "azure_region" {
  source       = "git::https://github.com/gravicore/terraform-gravicore-modules.git//azure/regions?ref=0.46.0"
  azure_region = var.az_region
}

# ----------------------------------------------------------------------------------------------------------------------
# VNET resource
# ----------------------------------------------------------------------------------------------------------------------

resource "azurerm_virtual_network" "default" {
  for_each            = var.create ? var.virtual_networks : {}
  name                = join(var.delimiter, compact([local.stage_prefix, var.application, module.azure_region.location_short, each.value.prefix, "vnet"]))
  resource_group_name = var.resource_group_name
  address_space       = coalesce(compact([each.value.vnet_cidr_block]))
  location            = var.az_region
  bgp_community       = each.value.bgp_community == null ? null : join(":", ["12076", each.value.bgp_community])

  dynamic "ddos_protection_plan" {
    for_each = each.value.ddos_protection_plan == null ? [] : [each.value.ddos_protection_plan]
    content {
      id     = ddos_protection_plan.value
      enable = ddos_protection_plan.enable
    }
  }
  dns_servers             = try(each.value.dns_servers, null)
  edge_zone               = try(each.value.edge_zone, null)
  flow_timeout_in_minutes = try(each.value.flow_timeout_in_minutes, null)
  tags                    = local.tags
}

# ----------------------------------------------------------------------------------------------------------------------
# Subnet resource
# ----------------------------------------------------------------------------------------------------------------------

resource "azurerm_subnet" "default" {
  for_each                          = var.create ? local.subnets_map : {}
  name                              = join(var.delimiter, [local.stage_prefix, var.application, module.azure_region.location_short, each.value.prefix, "snet"])
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.default[each.value.vnet_prefix].name
  address_prefixes                  = [cidrsubnet(azurerm_virtual_network.default[each.value.vnet_prefix].address_space[0], each.value.address_newbits, each.value.address_netnum)]
  service_endpoints                 = each.value.service_endpoints
  private_endpoint_network_policies = each.value.private_endpoint_network_policies

  dynamic "delegation" {
    for_each = each.value.delegation == null ? [] : [each.value.delegation]
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }
}

