resource "azurerm_key_vault" "default" {
  count               = var.create ? 1 : 0
  name                = join(var.delimiter, [local.stage_prefix, "kv"])
  location            = var.az_location
  resource_group_name = var.resource_group_name
  tags                = local.tags

  sku_name                        = var.sku_name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  access_policy                   = []
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment
  enable_rbac_authorization       = var.enable_rbac_authorization
  purge_protection_enabled        = var.purge_protection_enabled
  soft_delete_retention_days      = var.soft_delete_retention_days
  contact {
    email = var.contact_email
  }
}

resource "azurerm_key_vault_key" "vm-key" {
  count        = var.create ? 1 : 0
  name         = join(var.delimiter, [local.stage_prefix, "vm"])
  key_vault_id = concat(azurerm_key_vault.default.*.id, [""])[0]
  tags         = local.tags

  key_type = var.key_type
  key_size = var.key_size
}
