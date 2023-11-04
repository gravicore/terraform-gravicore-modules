# ----------------------------------------------------------------------------------------------------------------------
# CAF resource
# ----------------------------------------------------------------------------------------------------------------------

module "azure_region" {
  source       = "git::https://github.com/gravicore/terraform-gravicore-modules.git//azure/regions?ref=GDEV-336-release-azure"
  azure_region = var.az_region
}

# ----------------------------------------------------------------------------------------------------------------------
# Public IP resource
# ----------------------------------------------------------------------------------------------------------------------


resource "azurerm_public_ip" "default" {
  for_each                = { for ip in var.public_ip : ip.prefix => ip }
  location                = var.az_region
  name                    = join(var.delimiter, [local.stage_prefix, var.application, module.azure_region.location_short, each.key, var.name])
  resource_group_name     = var.resource_group_name
  allocation_method       = each.value.allocation_method
  zones                   = each.value.zones
  ddos_protection_mode    = each.value.ddos_protection_mode
  ddos_protection_plan_id = each.value.ddos_protection_plan_id
  domain_name_label       = each.value.domain_name_label
  edge_zone               = each.value.edge_zone
  idle_timeout_in_minutes = each.value.idle_timeout_in_minutes
  ip_tags                 = each.value.ip_tags
  ip_version              = each.value.ip_version
  public_ip_prefix_id     = each.value.public_ip_prefix_id
  reverse_fqdn            = each.value.reverse_fqdn
  sku                     = each.value.sku
  sku_tier                = each.value.sku_tier
  tags                    = local.tags
}

module "diagnostic" {
  source                = "git::https://github.com/gravicore/terraform-gravicore-modules.git//azure/diagnostic?ref=GDEV-336-release-azure"
  for_each              = { for ip in var.public_ip : ip.prefix => ip }
  create                = var.create && length(var.logs_destinations_ids) > 0 ? true : false
  namespace             = var.namespace
  environment           = var.environment
  stage                 = var.stage
  application           = var.application
  az_region             = var.az_region
  target_resource_id    = azurerm_public_ip.default[each.key].id
  logs_destinations_ids = var.logs_destinations_ids
}

