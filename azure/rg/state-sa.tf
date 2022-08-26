resource "azurerm_storage_account" "tfstate" {
  name                     = join("", [local.stage_prefix, "tf", "state"])
  resource_group_name      = concat(azurerm_resource_group.default.*.name, [""])[0]
  location                 = var.az_location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = local.tags

  depends_on = [
    azurerm_resource_group.default[0]
  ]
}

resource "azurerm_storage_container" "tfstate" {
  name                  = join("", [local.stage_prefix, "tf", "state"])
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "blob"
}
