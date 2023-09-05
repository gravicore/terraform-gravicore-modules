# ----------------------------------------------------------------------------------------------------------------------
# CAF resource
# ----------------------------------------------------------------------------------------------------------------------

module "azure_region" {
  source  = "claranet/regions/azurerm"
  version = "6.1.0"
  azure_region = var.region
}

# ----------------------------------------------------------------------------------------------------------------------
# VNET resource
# ----------------------------------------------------------------------------------------------------------------------

resource "azurerm_virtual_network" "default" {
  count                   = var.create ? 1 : 0
  name                    = local.module_prefix
  resource_group_name     = var.resource_group_name
  address_space           = coalesce(compact([var.vnet_cidr_block]))
  location                = var.region
  bgp_community           = var.bgp_community == null ? null : join(":", ["12076", var.bgp_community])

  dynamic "ddos_protection_plan" {
    for_each = var.ddos_protection_plan == null ? [] : [var.ddos_protection_plan]
    content {
      id = ddos_protection_plan.value
      enable = true
    }
  }
  dns_servers             = try(var.dns_servers, null)
  edge_zone               = try(var.edge_zone, null)
  flow_timeout_in_minutes = try(var.flow_timeout_in_minutes, null)
  tags                    = local.tags
}

# ----------------------------------------------------------------------------------------------------------------------
# Subnet resource
# ----------------------------------------------------------------------------------------------------------------------

resource "azurerm_subnet" "default" {
  for_each                                      = var.create ? local.subnets_map : {}
  name                                          = join(var.delimiter, [local.stage_prefix, var.application, module.azure_region.location_short, each.value.prefix, "snet"])
  resource_group_name                           = var.resource_group_name
  virtual_network_name                          = concat(azurerm_virtual_network.default.*.name, [""])[0]
  address_prefixes                              = coalesce([each.value.address_prefixes])
  service_endpoints                             = each.value.service_endpoints
  private_endpoint_network_policies_enabled     = each.value.private_endpoint_network_policies_enabled
  private_link_service_network_policies_enabled = each.value.private_link_service_network_policies_enabled

  dynamic "delegation" {
    for_each = each.value.delegation == null ? [] : [each.value.delegation]
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = compact(delegation.value.service_delegation.actions)
      }
    }
  }
}
