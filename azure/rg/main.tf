resource "azurerm_resource_group" "default" {
  count    = var.create ? 1 : 0
  location = var.az_location
  tags     = local.tags

  name = var.resource_group_name == "" ? local.stage_prefix : var.name
  # name     = var.resource_group_name == "" ? local.stage_prefix : var.resource_group_name
}
