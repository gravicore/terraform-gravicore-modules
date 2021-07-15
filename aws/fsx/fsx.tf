# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "active_directory_id" {
  type        = string
  default     = null
  description = "(Optional) The ID for an existing Microsoft Active Directory instance that the file system should join when it's created. Cannot be specified with self_managed_active_directory"
}

variable "storage_capacity" {
  type        = number
  default     = 2000
  description = "(Required) Storage capacity (GiB) of the file system. Minimum of 32 and maximum of 65536. If the storage type is set to HDD the minimum value is 2000"
}

variable "throughput_capacity" {
  type        = number
  default     = 1024
  description = "(Required) Throughput (megabytes per second) of the file system in power of 2 increments. Minimum of 8 and maximum of 2048"
}

variable "storage_type" {
  type        = string
  default     = "SSD"
  description = "(Optional) Specifies the storage type, Valid values are SSD and HDD. HDD is supported on SINGLE_AZ_2 and MULTI_AZ_1 Windows file system deployment types. Default value is SSD"
}

variable "copy_tags_to_backups" {
  type        = bool
  default     = true
  description = "(Optional) A boolean flag indicating whether tags on the file system should be copied to backups"
}

variable "deployment_type" {
  type        = string
  default     = "SINGLE_AZ_1"
  description = "(Optional) Specifies the file system deployment type, valid values are MULTI_AZ_1, SINGLE_AZ_1 and SINGLE_AZ_2. Default value is SINGLE_AZ_1"
}

variable "automatic_backup_retention_days" {
  type        = number
  default     = null
  description = "(Optional) The number of days to retain automatic backups. Minimum of 0 and maximum of 90. Defaults to 7. Set to 0 to disable"
}

variable daily_automatic_backup_start_time {
  type        = string
  default     = null
  description = "(Optional) The preferred time (in HH:MM format) to take daily automatic backups, in the UTC time zone"
}

variable security_group_ids {
  type        = list
  default     = []
  description = "(Optional) A list of IDs for the security groups that apply to the specified network interfaces created for file system access. These security groups will apply to all network interfaces"
}

variable "vpc_id" {
  type        = string
  default     = ""
  description = "The ID of the VPC"
}

variable "subnet_ids" {
  type        = list(string)
  description = "(Required) A list of IDs for the subnets that the file system will be accessible from. To specify more than a single subnet set deployment_type to MULTI_AZ_1"
}

variable ingress_cidrs {
  type    = list(string)
  default = []
}

variable "tcp_allowed_ports" {
  type = list(object({
    from_port = number
    to_port   = number
  }))
  default = []
}

variable "udp_allowed_ports" {
  type = list(object({
    from_port = number
    to_port   = number
  }))
  default = []
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "default" {
  count       = var.create && var.vpc_id != "" ? 1 : 0
  name        = local.module_prefix
  description = "common FSx ports"
  vpc_id      = var.vpc_id
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "Egress"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
  tags = local.tags
}

resource "aws_security_group_rule" "allow_ingress_cidr_tcp" {
  for_each          = var.create && var.tcp_allowed_ports != [] && var.vpc_id != "" ? { for port in var.tcp_allowed_ports : port.from_port => port } : {}
  security_group_id = aws_security_group.default[0].id
  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = "tcp"
  cidr_blocks       = var.ingress_cidrs
}

resource "aws_security_group_rule" "allow_ingress_cidr_udp" {
  for_each          = var.create && var.udp_allowed_ports != [] && var.vpc_id != "" ? { for port in var.udp_allowed_ports : port.from_port => port } : {}
  security_group_id = aws_security_group.default[0].id
  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = "udp"
  cidr_blocks       = var.ingress_cidrs
}

resource "aws_fsx_windows_file_system" "default" {
  count = var.create ? 1 : 0
  # kms_key_id          = aws_kms_key.example.arn # Not running custom KMS at time of this writing.
  active_directory_id               = var.active_directory_id
  storage_capacity                  = var.storage_capacity
  subnet_ids                        = var.subnet_ids
  throughput_capacity               = var.throughput_capacity
  automatic_backup_retention_days   = var.automatic_backup_retention_days
  daily_automatic_backup_start_time = var.daily_automatic_backup_start_time
  copy_tags_to_backups              = var.copy_tags_to_backups
  deployment_type                   = var.deployment_type
  preferred_subnet_id               = element(var.subnet_ids, 0)
  storage_type                      = var.storage_type
  security_group_ids = flatten([
    [concat(aws_security_group.default.*.id, [""])[0]],
    var.security_group_ids
  ])
  tags = local.tags
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "fsx" {
  description = "List the info for FSx"
  value       = aws_fsx_windows_file_system.default.*
}

output "fsx_id" {
  description = "List FSx id"
  value       = aws_fsx_windows_file_system.default.*.id
}

output "fsx_arn" {
  description = "List FSx id"
  value       = aws_fsx_windows_file_system.default.*.arn
}
