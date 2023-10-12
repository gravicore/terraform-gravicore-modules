# ----------------------------------------------------------------------------------------------------------------------
# CAF resource
# ----------------------------------------------------------------------------------------------------------------------

module "azure_region" {
  source       = "git::https://github.com/gravicore/terraform-gravicore-modules.git//azure/regions?ref=release-azure"
  azure_region = var.az_region
}

# ----------------------------------------------------------------------------------------------------------------------
# Keyvault resource
# ----------------------------------------------------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

data "azuread_group" "adgrp" {
  count        = length(local.azure_ad_group_names)
  display_name = local.azure_ad_group_names[count.index]
}

data "azuread_user" "adusr" {
  count               = length(local.azure_ad_user_principal_names)
  user_principal_name = local.azure_ad_user_principal_names[count.index]
}

data "azuread_service_principal" "adspn" {
  count        = length(local.azure_ad_service_principal_names)
  display_name = local.azure_ad_service_principal_names[count.index]
}

resource "azurerm_key_vault" "default" {
  count                           = var.create ? 1 : 0
  name                            = local.module_prefix
  location                        = var.az_region
  resource_group_name             = var.resource_group_name
  tags                            = local.tags
  sku_name                        = var.key_vault_sku_pricing_tier
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment
  public_network_access_enabled   = var.public_network_access_enabled
  enable_rbac_authorization       = var.enable_rbac_authorization
  purge_protection_enabled        = var.purge_protection_enabled
  soft_delete_retention_days      = var.soft_delete_retention_days

  dynamic "network_acls" {
    for_each = var.network_acls == null ? [] : [var.network_acls]
    content {
      bypass                     = try(network_acls.value.bypass, "AzureServices")
      default_action             = try(network_acls.value.default_action, "Deny")
      ip_rules                   = distinct(compact(network_acls.value.ip_rules))
      virtual_network_subnet_ids = distinct(compact(network_acls.value.virtual_network_subnet_ids))
    }
  }
  lifecycle {
    ignore_changes = [
      tags,
      contact
    ]
  }
}

resource "azurerm_key_vault_access_policy" "terraform" {
  count        = var.enable_rbac_authorization ? 0 : 1
  key_vault_id = one(azurerm_key_vault.default.*.id)
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions      = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"]
  key_permissions         = ["Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore", "Decrypt", "Encrypt", "UnwrapKey", "WrapKey", "Verify", "Sign", "Purge", "Release", "Rotate", "GetRotationPolicy", "SetRotationPolicy"]
  certificate_permissions = ["Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore", "ManageContacts", "ManageIssuers", "GetIssuers", "ListIssuers", "SetIssuers", "DeleteIssuers", "Purge"]
}

resource "azurerm_role_assignment" "terraform_rbac" {
  count                = var.enable_rbac_authorization ? 1 : 0
  scope                = one(azurerm_key_vault.default[*].id)
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_certificate_contacts" "default" {
  for_each = { for contact in var.certificate_contacts : contact.name => contact }

  key_vault_id = one(azurerm_key_vault.default.*.id)

  contact {
    name  = each.value.name
    email = each.value.email
    phone = each.value.phone
  }

  depends_on = [
    azurerm_key_vault_access_policy.terraform,
    azurerm_role_assignment.terraform_rbac,
  ]
}

resource "azurerm_key_vault_access_policy" "default" {
  count                   = var.enable_rbac_authorization ? 0 : length(local.combined_access_policies)
  key_vault_id            = one(azurerm_key_vault.default.*.id)
  tenant_id               = data.azurerm_client_config.current.tenant_id
  object_id               = coalesce(local.combined_access_policies[count.index].object_id, "")
  certificate_permissions = distinct(compact(local.combined_access_policies[count.index].certificate_permissions))
  key_permissions         = distinct(compact(local.combined_access_policies[count.index].key_permissions))
  secret_permissions      = distinct(compact(local.combined_access_policies[count.index].secret_permissions))
  storage_permissions     = distinct(compact(local.combined_access_policies[count.index].storage_permissions))
}

resource "azurerm_role_assignment" "key_vault_rbac" {
  count                = var.enable_rbac_authorization ? length(local.rbac_combined_access_policies) : 0
  scope                = one(azurerm_key_vault.default[*].id)
  role_definition_name = coalesce(local.rbac_combined_access_policies[count.index].role_definition_names[0], "")
  principal_id         = coalesce(local.rbac_combined_access_policies[count.index].object_id, "")
}


module "diagnostic" {
  create                = var.create && var.logs_destinations_ids != [] ? true : false
  source                = "git::https://github.com/gravicore/terraform-gravicore-modules.git//azure/diagnostic?ref=release-azure"
  namespace             = var.namespace
  environment           = var.environment
  stage                 = var.stage
  application           = var.application
  az_region             = var.az_region
  target_resource_id    = concat(azurerm_key_vault.default.*.id, [""])[0]
  logs_destinations_ids = var.logs_destinations_ids
}

