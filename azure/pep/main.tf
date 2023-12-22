# ----------------------------------------------------------------------------------------------------------------------
# CAF resource
# ----------------------------------------------------------------------------------------------------------------------

module "azure_region" {
  source       = "git::https://github.com/gravicore/terraform-gravicore-modules.git//azure/regions?ref=0.46.0"
  azure_region = var.az_region
}

# ----------------------------------------------------------------------------------------------------------------------
# Private endpoint creation
# ----------------------------------------------------------------------------------------------------------------------
resource "azurerm_private_endpoint" "default" {
  count                         = var.create ? 1 : 0
  name                          = local.module_prefix
  resource_group_name           = var.resource_group_name
  location                      = var.az_region
  subnet_id                     = var.subnet_id
  custom_network_interface_name = join(var.delimiter, [local.module_prefix, "nic"])

  dynamic "private_dns_zone_group" {
    for_each = local.is_not_private_link_service ? ["enabled"] : []
    content {
      name                 = local.private_dns_zone_group_name
      private_dns_zone_ids = var.private_dns_zone_ids
    }
  }

  private_service_connection {
    name                              = local.private_service_connection_name
    is_manual_connection              = var.is_manual_connection
    request_message                   = var.is_manual_connection ? var.request_message : null
    private_connection_resource_id    = local.resource_id
    private_connection_resource_alias = local.resource_alias
    subresource_names                 = local.is_not_private_link_service ? [var.subresource_name] : null
  }

  dynamic "ip_configuration" {
    for_each = var.ip_configurations != [] ? var.ip_configurations : null
    content {
      name               = ip_configuration.value.name
      member_name        = local.is_not_private_link_service ? ip_configuration.value.member_name : null
      subresource_name   = local.is_not_private_link_service ? coalesce(ip_configuration.value.subresource_name, var.subresource_name) : null
      private_ip_address = ip_configuration.value.private_ip_address
    }
  }


  tags = local.tags
}

