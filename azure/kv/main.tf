resource "azurerm_key_vault" "default" {
  count               = var.create ? 1 : 0
  name                = join(var.delimiter, [local.stage_prefix, "kv"])
  location            = var.az_location
  resource_group_name = var.resource_group_name
  tags                = local.tags

  sku_name  = var.sku_name
  tenant_id = data.azurerm_client_config.current.tenant_id
  # access_policy {
  #   tenant_id = data.azurerm_client_config.current.tenant_id
  #   object_id = var.access_policy_users[0]

  #   certificate_permissions = var.certificate_permissions
  #   key_permissions         = var.key_permissions
  #   secret_permissions      = var.secret_permissions
  # }
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment
  public_network_access_enabled   = var.public_network_access_enabled
  enable_rbac_authorization       = var.enable_rbac_authorization
  purge_protection_enabled        = var.purge_protection_enabled
  soft_delete_retention_days      = var.soft_delete_retention_days
  contact {
    email = var.contact_email
    name  = var.contact_name
    phone = var.contact_phone
  }
}

resource "azurerm_key_vault_access_policy" "default" {
  for_each     = var.create ? toset(var.access_policy_users) : toset([])
  key_vault_id = concat(azurerm_key_vault.default.*.id, [""])[0]
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = each.key

  key_permissions         = var.key_permissions
  secret_permissions      = var.secret_permissions
  certificate_permissions = var.certificate_permissions
}
