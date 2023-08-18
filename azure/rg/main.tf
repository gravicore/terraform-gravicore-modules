resource "azurerm_resource_group" "default" {
  count    = var.create ? 1 : 0
  location = var.az_location
  tags     = local.tags

  name = local.stage_prefix
}

# Creates a storage account & storage container to store the Terraform state file(s) for this Resource Group.
resource "azurerm_storage_account" "tfstate" {
  count               = var.create ? 1 : 0
  name                = join("", [var.namespace, var.environment, var.stage, "tf", "state"])
  resource_group_name = concat(azurerm_resource_group.default.*.name, [""])[0]
  location            = var.az_location
  tags                = local.tags

  account_tier             = "Standard"
  account_replication_type = "LRS"

  depends_on = [
    azurerm_resource_group.default[0]
  ]
}

resource "azurerm_storage_container" "tfstate" {
  count = var.create ? 1 : 0
  name  = join(var.delimiter, [var.namespace, var.environment, var.stage, "tf", "state"])

  storage_account_name  = concat(azurerm_storage_account.tfstate.*.name, [""])[0]
  container_access_type = "blob"
}
