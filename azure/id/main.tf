# ----------------------------------------------------------------------------------------------------------------------
# CAF resource
# ----------------------------------------------------------------------------------------------------------------------


module "azure_region" {
  source       = "claranet/regions/azurerm"
  version      = "6.1.0"
  azure_region = var.az_region
}


# ----------------------------------------------------------------------------------------------------------------------
# User Assigned Managed Identity
# ----------------------------------------------------------------------------------------------------------------------


data "azurerm_client_config" "current" {}


resource "azurerm_user_assigned_identity" "default" {
  for_each            = { for k, v in var.identity : k => v }
  name                = join(var.delimiter, [local.stage_prefix, var.application, module.azure_region.location_short, each.key, var.name])
  location            = var.az_region
  resource_group_name = var.resource_group_name
  tags                = var.tags
}


resource "azurerm_role_assignment" "default" {
  for_each = {
    for ra in local.flattened_role_assignments :
    "${ra.identity_name}-${ra.scope}" => ra
  }
  scope              = each.value.scope
  role_definition_id = each.value.role_definition_id
  principal_id       = azurerm_user_assigned_identity.default[each.value.index].principal_id
}



resource "azurerm_key_vault_access_policy" "default" {
  for_each = {
    for policy in local.flattened_kv_access_policies :
    "${policy.identity_name}-${policy.key_vault_id}" => policy
  }
  key_vault_id       = each.value.key_vault_id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = azurerm_user_assigned_identity.default[each.value.index].principal_id
  key_permissions    = each.value.key_permissions
  secret_permissions = each.value.secret_permissions
}

