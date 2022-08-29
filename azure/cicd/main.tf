resource "azurerm_role_definition" "elevated" {
  count = var.create ? 1 : 0
  name  = join(var.delimiter, [var.stage_prefix, "elevated", "access"])
  scope = data.azurerm_subscription.current.id

  permissions {
    actions     = ["*"]
    not_actions = []
  }

  assignable_scopes = [data.azurerm_subscription.current.id]
}

resource "azurerm_storage_account" "cicd" {
  count                    = var.create ? 1 : 0
  name                     = join("", [var.namespace, var.environment, var.stage, "cicd", "artifacts"])
  resource_group_name      = concat(local.resource_group_name, [""])[0]
  location                 = var.az_location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = local.tags
}

resource "azurerm_storage_container" "cicd" {
  count                 = var.create ? 1 : 0
  name                  = join("", [var.namespace, var.environment, var.stage, "cicd", "artifacts"])
  storage_account_name  = azurerm_storage_account.cicd.name
  container_access_type = "blob"
}

