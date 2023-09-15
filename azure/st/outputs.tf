output "storage_account_ids" {
  value       = { for k, v in azurerm_storage_account.default : k => v.id }
  description = "The IDs of the Storage Accounts"
}

