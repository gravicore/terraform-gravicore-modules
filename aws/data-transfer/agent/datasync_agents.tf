# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "vpc_id" {
  description = ""
  type        = string
}

variable "vpc_cidr_block" {
  description = ""
  type        = string
}

variable "vpc_private_subnets" {
  description = "A list of private VPC Subnet IDs to launch in"
  type        = list(string)
}

variable vpc_endpoint_id {
  type        = string
  default     = ""
  description = "(Optional) The ID of the VPC (virtual private cloud) endpoint that the agent has access to"
}

variable "datasync_ec2_instance_type" {
  description = "DataSync agent instance size must be at least 2xlarge"
  type        = string
  default     = "m5.2xlarge"
}

variable "datasync_agent_allowed_inbound_cidr_blocks" {
  description = "Allowed inbound CIDR blocks for DataSync Agent"
  type        = list(string)
  default     = []
}

variable "datasync_ec2_placement_group" {
  description = "(Optional) Placement Group to start the instance in"
  type        = string
  default     = null
}

variable "datasync_ec2_tenancy" {
  description = "(Optional) Tenancy of the instance (if the instance is running in a VPC). An instance with a tenancy of dedicated runs on single-tenant hardware. The host tenancy is not supported for the import-instance command"
  type        = string
  default     = "default"
}

variable "datasync_ec2_ebs_optimized" {
  description = "(Optional) If true, the launched EC2 instance will be EBS-optimized. Note that if this is not set on an instance type that is optimized by default then this will show as disabled but if the instance type is optimized by default then there is no need to set this and there is no effect to disabling it"
  type        = bool
  default     = true
}

variable "datasync_ec2_monitoring" {
  description = "(Optional) If true, the launched EC2 instance will have detailed monitoring enabled"
  type        = bool
  default     = true
}

variable "datasync_ec2_vpc_security_group_ids" {
  description = "(Optional) A list of security group IDs to associate with the instance"
  type        = list(string)
  default     = [""]
}

variable "datasync_ec2_private_ip" {
  description = "(Optional) Private IP address to associate with the instance in a VPC"
  type        = string
  default     = null
}

variable "datasync_ec2_source_dest_check" {
  description = "(Optional) Controls if traffic is routed to the instance when the destination address does not match the instance. Used for NAT or VPNs. Defaults true"
  type        = bool
  default     = true
}

variable ignore_ami_change {
  description = "If true, ignores updated AMI's which would cause datasync instance recreation"
  type        = bool
  default     = true
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

# EC2 host

resource "aws_security_group" "datasync" {
  count       = var.create ? 1 : 0
  name        = "${local.module_prefix}-datasync"
  description = join(" ", [var.desc_prefix, "Allow traffic to DataSync agent"])
  tags        = local.tags

  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = compact(distinct(concat([var.vpc_cidr_block], var.datasync_agent_allowed_inbound_cidr_blocks)))
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "datasync" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["aws-datasync-*"]
  }
}

resource "aws_instance" "datasync" {
  count = var.create ? 1 : 0
  tags = merge(local.tags,
    {
      "Name" = join("-", [local.module_prefix, "datasync"])
    },
  )

  volume_tags = merge(local.tags,
    {
      "Name" = join("-", [local.module_prefix, "datasync"])
    },
  )

  ami                    = data.aws_ami.datasync.id
  instance_type          = var.datasync_ec2_instance_type
  subnet_id              = element(var.vpc_private_subnets, count.index)
  monitoring             = var.datasync_ec2_monitoring
  vpc_security_group_ids = compact(concat(aws_security_group.datasync.*.id, var.datasync_ec2_vpc_security_group_ids))

  private_ip = var.datasync_ec2_private_ip

  ebs_optimized = var.datasync_ec2_ebs_optimized

  source_dest_check = var.datasync_ec2_source_dest_check
  placement_group   = var.datasync_ec2_placement_group
  tenancy           = var.datasync_ec2_tenancy

  lifecycle {
    ignore_changes = [
      ami,
    ]
  }
}

resource "aws_datasync_agent" "default" {
  count = var.create ? 1 : 0
  name  = join(var.delimiter, [local.module_prefix, "datasync"])
  tags  = local.tags

  ip_address            = aws_instance.datasync[0].private_ip
  security_group_arns   = ["arn:aws:ec2:${var.aws_region}:${var.account_id}:security-group/${aws_security_group.datasync[0].id}"]
  subnet_arns           = ["arn:aws:ec2:${var.aws_region}:${var.account_id}:subnet/${aws_instance.datasync[0].subnet_id}"]
  vpc_endpoint_id       = var.vpc_endpoint_id
  private_link_endpoint = data.aws_network_interface.datasync.private_ip
}

data "aws_vpc_endpoint" "datasync" {
  id = var.vpc_endpoint_id
}

data "aws_network_interface" "datasync" {
  id = tolist(data.aws_vpc_endpoint.datasync.network_interface_ids)[1]
}

# ----------------------------------------------------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------------------------------------------------

output "datasync_ami_id" {
  description = "ID of the DataSync AMI"
  value       = data.aws_ami.datasync.id
}

output "datasync_ec2_private_ip" {
  description = "Private IP of the DataSync EC2 Agent"
  value       = coalesce(aws_instance.datasync.*.private_ip, [""])[0]
}

output "datasync_agent_name" {
  description = "Name of the DataSync Agent"
  value       = var.create ? local.module_prefix : null
}

output "datasync_agent_tags" {
  description = "Tags of the DataSync Agent"
  value       = var.create ? local.tags : null
}

output "datasync_agent_id" {
  description = "ID of DataSync Agent"
  value       = split("/", element(aws_datasync_agent.default.*.id, 0))[1]
}

output "datasync_agent_arn" {
  description = "ARN of DataSync Agent"
  value       = coalesce(aws_datasync_agent.default.*.arn, [""])[0]
}
