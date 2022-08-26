# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

# variable "resource_group_name" {
#   type        = string
#   default     = ""
#   description = "The Name which should be used for this Resource Group. Changing this forces a new Resource Group to be created."
# }

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "azurerm_resource_group" "default" {
  count    = var.create ? 1 : 0
  location = var.az_location
  tags     = local.tags

  name = var.resource_group_name == "" ? local.stage_prefix : var.name
  # name     = var.resource_group_name == "" ? local.stage_prefix : var.resource_group_name
}

resource "azurerm_storage_account" "tfstate" {
  name                     = join(var.delimiter, [local.stage_prefix, "tf", "state"])
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
  name                  = join(var.delimiter, [local.stage_prefix, "tf", "state"])
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "blob"
}

# ----------------------------------------------------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------------------------------------------------

output "resource_group_name" {
  description = "The name of the Resource Group"
  value       = concat(azurerm_resource_group.default.*.name, [])[0]
}
