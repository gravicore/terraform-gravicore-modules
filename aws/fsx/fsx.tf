# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "map_migrated" {
  type        = string
  default     = ""
  description = ""
}

variable "map_migrated_app" {
  type        = string
  default     = ""
  description = ""
}

variable "aws_migration_project_id" {
  type        = string
  default     = ""
  description = ""
}

variable "active_directory_id" {
  description = "The ID of the Active Directory"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "vpc_private_subnets" {
  description = "List of IDs of private subnets"
  type        = list(string)
}


variable "storage_capacity" {
  type    = string
  default = ""
}


variable "throughput_capacity" {
  type    = string
  default = ""
}

variable "storage_type" {
  type    = string
  default = ""
}


variable "copy_tags_to_backups" {
  type        = bool
  default     = true
}

variable "deployment_type" {
  type    = string
  default = ""
}

variable "backup_retention_days" {
  type    = string
  default = ""
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_fsx_windows_file_system" "default" {
  # kms_key_id          = aws_kms_key.example.arn # Not running custom KMS at time of this writing.
  active_directory_id              = var.active_directory_id
  storage_capacity                 = var.storage_capacity
  subnet_ids                       = var.vpc_private_subnets
  throughput_capacity              = var.throughput_capacity
  automatic_backup_retention_days  = var.backup_retention_days
  copy_tags_to_backups             = var.copy_tags_to_backups
  deployment_type                  = var.deployment_type
  preferred_subnet_id              = element(var.vpc_private_subnets, 0)
  storage_type                     = var.storage_type
  security_group_ids               = [
    aws_security_group.fsxsg1[0].id,
    aws_security_group.fsxsg2[0].id,
    aws_security_group.fsxsg3[0].id,
    aws_security_group.fsxsg4[0].id,
  ]
  tags                             = local.tags
}



##################################################################################################################
# Security group for Amazon FSx.
##################################################################################################################

variable ingress_cidrs_1 {
  type        = list(string)
  default     = [""]
  description = "description"
}

variable ingress_cidrs_2 {
  type        = list(string)
  default     = [""]
  description = "description"
}

variable ingress_cidrs_3 {
  type        = list(string)
  default     = [""]
  description = "description"
}

variable ingress_cidrs_4 {
  type        = list(string)
  default     = [""]
  description = "description"
}


variable "fsx_tcp_allowed_ports" {
  type = list(object({
    from_port = number
    to_port = number
  }))
}


variable "fsx_udp_allowed_ports" {
  type = list(object({
    from_port = number
    to_port = number
  }))
}


# ----------------------------------------------
####### Security Group 1
# ----------------------------------------------
resource "aws_security_group" "fsxsg1" {
  count = var.create ? 1 : 0
  name  = join("-", [local.module_prefix, "1"])
  description = "common FSx ports"
  vpc_id      = var.vpc_id
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "Egress"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
  tags = merge(local.tags,map(
    "map-migrated", "",
  ))
}

 
resource "aws_security_group_rule" "allow_ingress_cidr_tcp_1" {
  for_each = {for port in var.fsx_tcp_allowed_ports:  port.from_port => port}
  security_group_id = aws_security_group.fsxsg1[0].id
  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = "tcp"
  cidr_blocks       = var.ingress_cidrs_1
}

resource "aws_security_group_rule" "allow_ingress_cidr_udp_1" {
  for_each = {for port in var.fsx_udp_allowed_ports:  port.from_port => port}
  security_group_id = aws_security_group.fsxsg1[0].id
  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = "udp"
  cidr_blocks       = var.ingress_cidrs_1
}

# ----------------------------------------------
####### Security Group 2
# ----------------------------------------------
resource "aws_security_group" "fsxsg2" {
  count = var.create ? 1 : 0
  name  = join("-", [local.module_prefix, "2"])
  description = "common FSx ports"
  vpc_id      = var.vpc_id
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "Egress"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
  tags = merge(local.tags,map(
    "map-migrated", "",
  ))
}

resource "aws_security_group_rule" "allow_ingress_cidr_tcp_2" {
  for_each = {for port in var.fsx_tcp_allowed_ports:  port.from_port => port}
  security_group_id = aws_security_group.fsxsg2[0].id
  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = "tcp"
  cidr_blocks       = var.ingress_cidrs_2
}

resource "aws_security_group_rule" "allow_ingress_cidr_udp_2" {
  for_each = {for port in var.fsx_udp_allowed_ports:  port.from_port => port}
  security_group_id = aws_security_group.fsxsg2[0].id
  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = "udp"
  cidr_blocks       = var.ingress_cidrs_2
}

# ----------------------------------------------
####### Security Group 3
# ----------------------------------------------
resource "aws_security_group" "fsxsg3" {
  count = var.create ? 1 : 0
  name  = join("-", [local.module_prefix, "3"])
  description = "common FSx ports"
  vpc_id      = var.vpc_id
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "Egress"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
  tags = merge(local.tags,map(
    "map-migrated", "",
  ))
}

resource "aws_security_group_rule" "allow_ingress_cidr_tcp_3" {
  for_each = {for port in var.fsx_tcp_allowed_ports:  port.from_port => port}
  security_group_id = aws_security_group.fsxsg3[0].id
  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = "tcp"
  cidr_blocks       = var.ingress_cidrs_3
}

resource "aws_security_group_rule" "allow_ingress_cidr_udp_3" {
  for_each = {for port in var.fsx_udp_allowed_ports:  port.from_port => port}
  security_group_id = aws_security_group.fsxsg3[0].id
  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = "udp"
  cidr_blocks       = var.ingress_cidrs_3
}

# ----------------------------------------------
####### Security Group 4
# ----------------------------------------------
resource "aws_security_group" "fsxsg4" {
  count = var.create ? 1 : 0
  name  = join("-", [local.module_prefix, "4"])
  description = "common FSx ports"
  vpc_id      = var.vpc_id
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "Egress"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
  tags = merge(local.tags,map(
    "map-migrated", "",
  ))
}


resource "aws_security_group_rule" "allow_ingress_cidr_tcp_4" {
  for_each = {for port in var.fsx_tcp_allowed_ports:  port.from_port => port}
  security_group_id = aws_security_group.fsxsg4[0].id
  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = "tcp"
  cidr_blocks       = var.ingress_cidrs_4
}

resource "aws_security_group_rule" "allow_ingress_cidr_udp_4" {
  for_each = {for port in var.fsx_udp_allowed_ports:  port.from_port => port}
  security_group_id = aws_security_group.fsxsg4[0].id
  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = "udp"
  cidr_blocks       = var.ingress_cidrs_4
}




# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "fsx" {
  description = "List the info for FSx"
  value       = aws_fsx_windows_file_system.default.*
}
