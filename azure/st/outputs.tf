output "storage_account_ids" {
  value       = { for k, v in azurerm_storage_account.default : k => v.id }
  description = "The IDs of the Storage Accounts"
}

output "private_endpoint_record_sets" {
  value       = { for k, v in module.private_endpoint : k => v.private_endpoint_record_sets }
  description = "The Record Sets of the Private Endpoints"
}