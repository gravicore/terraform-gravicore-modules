# ----------------------------------------------------------------------------------------------------------------------
# CAF resource
# ----------------------------------------------------------------------------------------------------------------------


module "azure_region" {
  source       = "git::https://github.com/gravicore/terraform-gravicore-modules.git//azure/regions?ref=GDEV-336-release-azure"
  azure_region = var.az_region
}


# ----------------------------------------------------------------------------------------------------------------------
# Resource Group resource
# ----------------------------------------------------------------------------------------------------------------------


resource "azurerm_resource_group" "default" {
  count    = var.create ? 1 : 0
  name     = local.module_prefix
  location = var.az_region
  tags     = local.tags
}

resource "azurerm_management_lock" "default" {
  count      = var.create && var.lock_level != null ? 1 : 0
  name       = join(var.delimiter, [local.module_prefix, "lock"])
  scope      = azurerm_resource_group.default[count.index].id
  lock_level = var.lock_level
  notes      = "Resource Group '${azurerm_resource_group.default[count.index].name}' is locked with '${var.lock_level}' level."
}

