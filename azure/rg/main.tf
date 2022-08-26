resource "azurerm_resource_group" "default" {
  count    = var.create ? 1 : 0
  location = var.az_location
  tags     = local.tags

  name = local.stage_prefix
}
