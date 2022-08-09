# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "resource_group_name" {
  type        = string
  default     = ""
  description = "The Name which should be used for this Resource Group. Changing this forces a new Resource Group to be created."
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "azurerm_resource_group" "default" {
  count    = var.create ? 1 : 0
  location = var.az_location
  tags     = local.tags

  name = var.resource_group_name == "" ? join(var.delimiter, [local.stage_prefix, "resource-group"]) : var.resource_group_name
  # name     = var.resource_group_name == "" ? local.stage_prefix : var.resource_group_name
}

# ----------------------------------------------------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------------------------------------------------

output "resource_group_name" {
  description = "The name of the Resource Group"
  value       = concat(azurerm_resource_group.default[0].name, [])
}
