# ----------------------------------------------------------------------------------------------------------------------
# CAF resource
# ----------------------------------------------------------------------------------------------------------------------


module "azure_region" {
  source       = "claranet/regions/azurerm"
  version      = "6.1.0"
  azure_region = var.az_region
}


# ----------------------------------------------------------------------------------------------------------------------
# Container Environment
# ----------------------------------------------------------------------------------------------------------------------

resource "azurerm_container_app_environment" "default" {
  count                          = var.create ? 1 : 0
  location                       = var.az_region
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  name                           = local.module_prefix
  resource_group_name            = var.resource_group_name
  infrastructure_subnet_id       = var.infrastructure_subnet_id
  internal_load_balancer_enabled = var.internal_load_balancer_enabled
  tags                           = local.tags
}

# ----------------------------------------------------------------------------------------------------------------------
# Container Environment Dapr Component
# ----------------------------------------------------------------------------------------------------------------------

resource "azurerm_container_app_environment_dapr_component" "default" {
  for_each = var.dapr_component

  component_type               = each.value.component_type
  container_app_environment_id = one(azurerm_container_app_environment.default.*.id)
  name                         = join(var.delimiter, [local.module_prefix, "dapr"])
  version                      = each.value.version
  ignore_errors                = each.value.ignore_errors
  init_timeout                 = each.value.init_timeout
  scopes                       = each.value.scopes

  dynamic "metadata" {
    for_each = each.value.metadata == null ? [] : each.value.metadata

    content {
      name        = metadata.value.name
      secret_name = metadata.value.secret_name
      value       = metadata.value.value
    }
  }
  dynamic "secret" {
    for_each = nonsensitive(toset([for pair in lookup(var.dapr_component_secrets, each.key, []) : pair.name]))

    content {
      name  = secret.key
      value = local.dapr_component_secrets[each.key][secret.key]
    }
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# Container Environment Storage
# ----------------------------------------------------------------------------------------------------------------------

resource "azurerm_container_app_environment_storage" "storage" {
  for_each = var.env_storage

  access_key                   = var.environment_storage_access_key[each.key]
  access_mode                  = each.value.access_mode
  account_name                 = each.value.account_name
  container_app_environment_id = one(azurerm_container_app_environment.default.*.id)
  name                         = join(var.delimiter, [local.module_prefix, "st"])
  share_name                   = each.value.share_name
}


resource "azurerm_private_dns_a_record" "default" {
  count               = var.internal_load_balancer_enabled && var.dns_a_record != null ? 1 : 0
  name                = var.dns_a_record.name
  zone_name           = var.dns_a_record.zone_name
  resource_group_name = var.dns_a_record.resource_group_name
  ttl                 = var.dns_a_record.ttl
  records             = [azurerm_container_app_environment.default[0].static_ip_address]
}
