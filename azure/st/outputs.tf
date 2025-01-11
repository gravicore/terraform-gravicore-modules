output "storage_account_ids" {
  value       = { for k, v in azurerm_storage_account.default : k => v.id }
  description = "The IDs of the Storage Accounts"
}

output "private_endpoint_fqdn" {
  value       = { for k, v in module.private_endpoint : k => v.private_endpoint_fqdn }
  description = "The FQDN of the Private Endpoints"
}

output "storage_account_blob_urls" {
  value       = { for k, v in azurerm_storage_account.default : k => v.primary_blob_endpoint }
  description = "The Blob URLs of the Storage Accounts"
}

output "storage_account_table_urls" {
  value       = { for k, v in azurerm_storage_account.default : k => v.primary_table_endpoint }
  description = "The Table URLs of the Storage Accounts"
}

output "storage_account_queue_urls" {
  value       = { for k, v in azurerm_storage_account.default : k => v.primary_queue_endpoint }
  description = "The Queue URLs of the Storage Accounts"
}

output "storage_account_file_urls" {
  value       = { for k, v in azurerm_storage_account.default : k => v.primary_file_endpoint }
  description = "The File URLs of the Storage Accounts"
}
