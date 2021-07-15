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

module "datasync_ec2" {
  instance_count = var.create ? 1 : 0
  source         = "terraform-aws-modules/ec2-instance/aws"
  version        = "2.12.0"
  name           = "${local.module_prefix}-datasync"
  tags           = local.tags
  volume_tags    = local.tags

  ami                    = data.aws_ami.datasync.id
  instance_type          = var.datasync_ec2_instance_type
  subnet_ids             = var.vpc_private_subnets
  ebs_optimized          = true
  monitoring             = true
  vpc_security_group_ids = [aws_security_group.datasync[0].id]
}

resource "aws_datasync_agent" "default" {
  count = var.create ? 1 : 0
  name  = join(var.delimiter, [local.module_prefix, "datasync"])
  tags  = local.tags

  ip_address            = module.datasync_ec2.private_ip[0]
  security_group_arns   = ["arn:aws:ec2:${var.aws_region}:${var.account_id}:security-group/${aws_security_group.datasync[0].id}"]
  subnet_arns           = ["arn:aws:ec2:${var.aws_region}:${var.account_id}:subnet/${module.datasync_ec2.subnet_id[0]}"] # [for s in var.vpc_private_subnets : "arn:aws:ec2:${var.aws_region}:${var.account_id}:subnet/${s}"]
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
  value       = length(module.datasync_ec2.private_ip) > 0 ? module.datasync_ec2.private_ip[0] : null
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
  description = ""
  value       = aws_datasync_agent.default.*.id
}

output "datasync_agent_arn" {
  description = ""
  value       = aws_datasync_agent.default.*.arn
}
