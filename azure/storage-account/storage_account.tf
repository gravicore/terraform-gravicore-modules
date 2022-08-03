# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "account_kind" {
  type        = string
  default     = "Storagev2"
  description = "(Optional) Defines the Kind of account. Valid options are BlobStorage, BlockBlobStorage, FileStorage, Storage and StorageV2. Changing this forces a new resource to be created. Defaults to StorageV2"
}

variable "account_tier" {
  type        = string
  default     = "Standard"
  description = "(Required) Defines the Tier to use for this storage account. Valid options are Standard and Premium. For BlockBlobStorage and FileStorage accounts only Premium is valid. Changing this forces a new resource to be created."
}

variable "account_replication_type" {
  type        = string
  default     = "LRS" # ? Default value is correct?
  description = "(Required) Defines the type of replication to use for this storage account. Valid options are LRS, GRS, RAGRS, ZRS, GZRS and RAGZRS. Changing this forces a new resource to be created when types LRS, GRS and RAGRS are changed to ZRS, GZRS or RAGZRS and vice versa."
}

variable "cross_tenant_replication_enabled" {
  type        = bool
  default     = true
  description = "(Optional) Should cross Tenant replication be enabled? Defaults to true"
}

variable "access_tier" {
  type        = string
  default     = "Hot"
  description = "(Optional) Defines the access tier for BlobStorage, FileStorage and StorageV2 accounts. Valid options are Hot and Cool, defaults to Hot."
}

variable "edge_zone" {
  type        = bool
  default     = null # ? Default value is correct?
  description = "(Optional) Specifies the Edge Zone within the Azure Region where this Storage Account should exist. Changing this forces a new Storage Account to be created."
}

variable "enable_https_traffic_only" {
  type        = bool
  default     = true
  description = "(Optional) Boolean flag which forces HTTPS if enabled, see here for more information. Defaults to true."
}

variable "min_tls_version" {
  type        = string
  default     = "TLS1_2"
  description = "(Optional) The minimum supported TLS version for the storage account. Possible values are TLS1_0, TLS1_1, and TLS1_2. Defaults to TLS1_2 for new storage accounts."
}

variable "allow_nested_items_to_be_public" {
  type        = bool
  default     = true # ? Default value is correct?
  description = "Allow or disallow nested items within this Account to opt into being public. Defaults to true."
}

variable "shared_access_key_enabled" {
  type        = bool
  default     = true
  description = " Indicates whether the storage account permits requests to be authorized with the account access key via Shared Key. If false, then all requests, including shared access signatures, must be authorized with Azure Active Directory (Azure AD). The default value is true."
}

variable "is_hns_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Is Hierarchical Namespace enabled? This can be used with Azure Data Lake Storage Gen 2. Changing this forces a new resource to be created."
}

variable "nfsv3_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Is NFSv3 protocol enabled? Changing this forces a new resource to be created. Defaults to false."
}

variable "large_file_share_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Is Large File Share Enabled?"
}

variable "queue_encryption_key_type" {
  type        = string
  default     = "Service"
  description = "(Optional) The encryption type of the queue service. Possible values are Service and Account. Changing this forces a new resource to be created. Default value is Service."
}

variable "table_encryption_key_type" {
  type        = string
  default     = "Service"
  description = "(Optional) The encryption type of the table service. Possible values are Service and Account. Changing this forces a new resource to be created. Default value is Service."
}

variable "infrastructure_encryption_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Is infrastructure encryption enabled? Changing this forces a new resource to be created. Defaults to false."
}

variable "customer_managed_key" {
  type        = map(any)
  default     = {}
  description = "value"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "azurerm_storage_account" "default" {
  count               = var.create ? 1 : 0
  name                = var.name
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

  # dynamic "customer_managed_key" {
  #   for_each = toset(var.customer_managed_key)
  #   content {
  #     key_vault_key_id          = lookup(var.customer_managed_key, "key_vault_id", "")
  #     user_assigned_identity_id = lookup(var.customer_managed_key, "user_assigned_identity_id", "")
  #   }
  # }

  customer_managed_key {
    key_vault_key_id          = lookup(var.customer_managed_key, "key_vault_id", "")
    user_assigned_identity_id = lookup(var.customer_managed_key, "user_assigned_identity_id", "")
  }

  large_file_share_enabled = var.large_file_share_enabled

  queue_encryption_key_type         = var.queue_encryption_key_type
  table_encryption_key_type         = var.table_encryption_key_type
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled
}

# ----------------------------------------------------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------------------------------------------------

output "storage_account_name" {
  description = "The name of the Storage Account"
  value       = concat(azurerm_storage_account.default[0].name, [])
}

output "storage_account_kind" {
  description = "The kind of the Storage Account"
  value       = concat(azurerm_storage_account.default[0].account_kind, [])
}

output "storage_account_type" {
  description = "The tier of the Storage Account"
  value       = concat(azurerm_storage_account.default[0].account_tier, [])
}
