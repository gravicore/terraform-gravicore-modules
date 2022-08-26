resource "azurerm_storage_account" "tfstate" {
  name                     = join(var.delimiter, [var.name_prefix, "remote-state"])
  resource_group_name      = concat(azurerm_resource_group.default.*.name, [""])[0]
  location                 = var.az_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_blob_public_access = true

  tags = local.tags
}

resource "azurerm_storage_container" "tfstate" {
  name                  = join(var.delimiter, [var.name_prefix, "remote-state"])
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "blob"
}
