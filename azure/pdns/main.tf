# ----------------------------------------------------------------------------------------------------------------------
# CAF resource
# ----------------------------------------------------------------------------------------------------------------------


module "azure_region" {
  source       = "git::https://github.com/gravicore/terraform-gravicore-modules.git//azure/regions?ref=0.46.0"
  azure_region = var.az_region
}


# ----------------------------------------------------------------------------------------------------------------------
# Private DNS Zone
# ----------------------------------------------------------------------------------------------------------------------


resource "azurerm_private_dns_zone" "default" {
  for_each            = var.create ? var.private_dns_zones : {}
  name                = each.value.name
  resource_group_name = var.resource_group_name
  tags                = local.tags

  lifecycle {
    precondition {
      condition     = each.value.is_not_private_link_service
      error_message = "Private Link Service does not require the deployment of Private DNS Zones."
    }
  }
}


# ----------------------------------------------------------------------------------------------------------------------
# Private DNS Zone Virtual Network Links
# ----------------------------------------------------------------------------------------------------------------------


resource "azurerm_private_dns_zone_virtual_network_link" "default" {
  for_each = var.create ? { for item in local.flattened_dns_zones : "${item.key}-${item.vnet_id}" => item } : {}

  depends_on            = [azurerm_private_dns_zone.default]
  name                  = format("%s-%s-link", azurerm_private_dns_zone.default[each.value.key].name, basename(each.value.vnet_id))
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = each.value.name
  virtual_network_id    = each.value.vnet_id
  registration_enabled  = each.value.vm_autoregistration_enabled
  tags                  = local.tags

  lifecycle {
    precondition {
      condition     = each.value.is_not_private_link_service
      error_message = "Private Link Service does not require the deployment of Private DNS Zone VNet Links."
    }
  }
}

