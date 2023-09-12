# ----------------------------------------------------------------------------------------------------------------------
# CAF resource
# ----------------------------------------------------------------------------------------------------------------------

module "azure_region" {
  source       = "claranet/regions/azurerm"
  version      = "6.1.0"
  azure_region = var.region
}


# ----------------------------------------------------------------------------------------------------------------------
# Private DNS Zone
# ----------------------------------------------------------------------------------------------------------------------


resource "azurerm_private_dns_zone" "default" {
  count               = var.create && length(var.private_dns_zones) > 0 ? length(var.private_dns_zones) : 0
  name                = var.private_dns_zones[count.index].name
  resource_group_name = var.private_dns_zones[count.index].resource_group_name
  tags                = local.tags

  lifecycle {
    precondition {
      condition     = var.private_dns_zones[count.index].is_not_private_link_service
      error_message = "Private Link Service does not require the deployment of Private DNS Zones."
    }
  }
}


# ----------------------------------------------------------------------------------------------------------------------
# Private DNS Zone Virtual Network Links
# ----------------------------------------------------------------------------------------------------------------------


resource "azurerm_private_dns_zone_virtual_network_link" "default" {
  depends_on = [azurerm_private_dns_zone.default]
  count      = length(local.flattened_dns_zones)
  name = format(
    "%s-%s-link",
    element(azurerm_private_dns_zone.default.*.name, count.index),
    basename(local.flattened_dns_zones[count.index].vnet_id)
  )
  resource_group_name   = local.flattened_dns_zones[count.index].resource_group_name
  private_dns_zone_name = local.flattened_dns_zones[count.index].name
  virtual_network_id    = local.flattened_dns_zones[count.index].vnet_id
  registration_enabled  = local.flattened_dns_zones[count.index].vm_autoregistration_enabled
  tags                  = local.tags

  lifecycle {
    precondition {
      condition     = local.flattened_dns_zones[count.index].is_not_private_link_service
      error_message = "Private Link Service does not require the deployment of Private DNS Zone VNet Links."
    }
  }
}

