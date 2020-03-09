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
