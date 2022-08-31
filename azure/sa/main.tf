resource "azurerm_storage_account" "default" {
  count               = var.create ? 1 : 0
  name                = join("", [var.namespace, var.environment, var.stage, var.name])
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

  customer_managed_key {
    key_vault_key_id          = var.key_vault_key_id
    user_assigned_identity_id = var.user_assigned_identity_id
  }

  large_file_share_enabled          = var.large_file_share_enabled
  queue_encryption_key_type         = var.queue_encryption_key_type
  table_encryption_key_type         = var.table_encryption_key_type
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled
}

resource "azurerm_storage_container" "default" {
  count                 = var.create ? 1 : 0
  name                  = local.module_prefix
  storage_account_name  = concat(azurerm_storage_account.default.*.name, [""])[0]
  container_access_type = "blob"
}

