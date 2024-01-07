# ----------------------------------------------------------------------------------------------------------------------
# CAF resource
# ----------------------------------------------------------------------------------------------------------------------


module "azure_region" {
  source       = "git::https://github.com/gravicore/terraform-gravicore-modules.git//azure/regions?ref=0.46.0"
  azure_region = var.az_region
}


# ----------------------------------------------------------------------------------------------------------------------
# Private Link Service
# ----------------------------------------------------------------------------------------------------------------------


resource "azurerm_private_link_service" "default" {
  for_each            = var.create && length(var.private_link_service) > 0 ? var.private_link_service : {}
  location            = var.az_region
  resource_group_name = var.resource_group_name
  name                = join(var.delimiter, compact([local.stage_prefix, var.application, module.azure_region.location_short, each.value.prefix, var.name]))

  auto_approval_subscription_ids              = each.value.auto_approval_subscription_ids
  visibility_subscription_ids                 = each.value.visibility_subscription_ids
  load_balancer_frontend_ip_configuration_ids = each.value.load_balancer_frontend_ip_configuration_ids
  enable_proxy_protocol                       = each.value.enable_proxy_protocol
  fqdns                                       = each.value.fqdns

  dynamic "nat_ip_configuration" {
    for_each = each.value.nat_ip_configurations
    content {
      name                       = nat_ip_configuration.value.name
      private_ip_address         = nat_ip_configuration.value.private_ip_address
      private_ip_address_version = nat_ip_configuration.value.private_ip_address_version
      subnet_id                  = nat_ip_configuration.value.subnet_id
      primary                    = nat_ip_configuration.value.primary
    }
  }
}

module "diagnostic" {
  for_each              = var.create ? { for key, val in var.private_link_service : key => val if can(val.logs_destinations_ids) && length(val.logs_destinations_ids) > 0 } : {}
  source                = "git::https://github.com/gravicore/terraform-gravicore-modules.git//azure/diagnostic?ref=0.46.0"
  namespace             = var.namespace
  environment           = var.environment
  stage                 = var.stage
  application           = var.application
  az_region             = var.az_region
  target_resource_id    = azurerm_private_link_service.default[each.key].id
  logs_destinations_ids = each.value.logs_destinations_ids
}

