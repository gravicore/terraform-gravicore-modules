# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "resource_group_name" {
  type        = string
  default     = ""
  description = "The name of the Resource Group"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "azurerm_resource_group" "default" {
  count    = var.create ? 1 : 0
  name     = var.resource_group_name == "" ? join(var.delimiter, [local.stage_prefix, "resource-group"]) : var.resource_group_name
  location = var.az_location
}

# ----------------------------------------------------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------------------------------------------------

output "resource_group_name" {
  description = "The name of the Resource Group"
  value       = concat(azurerm_resource_group.default[0].name, [])
}
