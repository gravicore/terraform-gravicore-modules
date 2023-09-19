# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "az_max_count" {
  type        = number
  default     = 2
  description = "Sets the maximum number of Availability Zones (up to 3)"
}

variable "az_zone_ids_priority" {
  type        = list(string)
  default     = ["use1-az6", "use1-az2", "use1-az1"]
  description = ""
}

variable "az_names" {
  type        = list(string)
  default     = []
  description = "Sets the Availability Zones to use"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

# Calculate best AZs to use

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  az_zone_ids_available = distinct(compact(concat(var.az_zone_ids_priority, data.aws_availability_zones.available.zone_ids)))
  az_zone_ids           = chunklist(local.az_zone_ids_available, var.az_max_count)[0]
}

data "aws_availability_zone" "ids" {
  for_each = toset(local.az_zone_ids_available)
  zone_id  = each.key
}

locals {
  az_names_available = [for zone_id in local.az_zone_ids_available : data.aws_availability_zone.ids[zone_id].name]
  az_names = coalescelist(
    var.az_names,
    [for zone_id in local.az_zone_ids : data.aws_availability_zone.ids[zone_id].name],
  )
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "vpc_az_zone_ids_available" {
  description = "List of the available Availability Zone IDs"
  value       = local.az_zone_ids_available
}

output "vpc_azs_available" {
  description = "List of the available Availability Zones for the VPC"
  value = [for zone_id in local.az_zone_ids_available : {
    zone_id = zone_id
    name    = data.aws_availability_zone.ids[zone_id].name
  }]
}

output "vpc_az_names_available" {
  description = "List of the available Availability Zone names"
  value       = local.az_names_available
}

output "vpc_azs" {
  description = "List of Availability Zones used for the VPC"
  value = [for zone_id in local.az_zone_ids : {
    zone_id = zone_id
    name    = data.aws_availability_zone.ids[zone_id].name
  }]
}

output "vpc_az_names" {
  description = "List of Availability Zone names used for the VPC"
  value       = local.az_names
}

output "vpc_az_zone_ids" {
  description = "List of Availability Zone IDs used for the VPC"
  value       = local.az_zone_ids
}
