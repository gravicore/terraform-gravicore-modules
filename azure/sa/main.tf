resource "azurerm_storage_account" "default" {
  count               = var.create ? 1 : 0
  name                = join("", concat([var.namespace, var.environment, var.stage], split(" ", var.name)))
  resource_group_name = var.resource_group_name
  location            = var.az_location
  tags                = local.tags

  account_kind                     = var.account_kind
  account_tier                     = var.account_tier
  account_replication_type         = var.account_replication_type
  cross_tenant_replication_enabled = var.cross_tenant_replication_enabled
  access_tier                      = var.access_tier
  edge_zone                        = var.edge_zone
  enable_https_traffic_only        = var.enable_https_traffic_only
  min_tls_version                  = var.min_tls_version
  allow_nested_items_to_be_public  = var.allow_nested_items_to_be_public
  shared_access_key_enabled        = var.shared_access_key_enabled
  is_hns_enabled                   = var.is_hns_enabled
  nfsv3_enabled                    = var.nfsv3_enabled

  large_file_share_enabled          = var.large_file_share_enabled
  queue_encryption_key_type         = var.queue_encryption_key_type
  table_encryption_key_type         = var.table_encryption_key_type
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_storage_container" "default" {
  count                 = var.create ? 1 : 0
  name                  = join(var.delimiter, concat([local.stage_prefix], split(" ", var.name)))
  storage_account_name  = concat(azurerm_storage_account.default.*.name, [""])[0]
  container_access_type = "blob"
}

resource "azurerm_storage_account_customer_managed_key" "default" {
  storage_account_id = concat(azurerm_storage_account.default.*.id, [""])[0]
  key_vault_id       = var.key_vault_key_id
  key_name           = var.key_name
}


resource "azurerm_key_vault_access_policy" "storage" {
  key_vault_id = var.key_vault_key_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_storage_account.default[0].identity.0.principal_id

  key_permissions    = ["get", "create", "list", "restore", "recover", "unwrapkey", "wrapkey", "purge", "encrypt", "decrypt", "sign", "verify"]
  secret_permissions = ["get"]
}
