# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "admin_email" {
  description = "The administrator's email address that will be used for password recovery as well as for notifications from the Controller"
  type        = string
}

variable "access_account_name" {
  description = "A friendly name mapping to your AWS account ID"
  type        = string
  default     = ""
}

locals {
  access_account_name = coalesce(var.access_account_name, local.stage_prefix)
  admin_username      = "admin"
}

variable "vpc_id" {
  description = "The VPC ID where the Controller will be installed"
  type        = string
}

variable "vpc_public_subnets" {
  description = "The public subnet IDs where the Controller instance will reside."
  type        = list(string)
}

variable "key_pair" {
  description = "The name of the AWS Key Pair (required when building an AWS EC2 instance)."
  type        = string
}

variable "aviatrix_iam_role_ec2_name" {
  description = "The name of the aviatrix-ec2-role IAM role"
  type        = string
  default     = "aviatrix-role-ec2"
}

variable "instance_type" {
  description = "The instance size for the Aviatrix controller instance"
  type        = string
  default     = "t2.large"
}

variable "root_volume_size" {
  description = "The size of the hard disk for the controller instance"
  type        = number
  default     = null
}

variable "root_volume_type" {
  description = "The type of the hard disk for the controller instance, Default value is `standard`"
  type        = string
  default     = "standard"
}

variable "incoming_ssl_cidr" {
  description = "The CIDR to be allowed for HTTPS(port 443) access to the controller"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "license_type" {
  description = "The license type for the Aviatrix controller. Valid values are `metered`, `BYOL`"
  type        = string
  default     = "metered"
}

variable "customer_license_id" {
  description = "The customer license ID is required if using a BYOL controller"
  type        = string
  default     = ""
}

variable "termination_protection" {
  description = "Whether termination protection is enabled for the controller"
  type        = bool
  default     = false
}

variable "enable_ha" {
  description = "Enable HA mode for the Aviatrix Controller"
  type        = bool
  default     = false
}

data "aws_ami" "metered" {
  for_each = var.create && var.license_type == "metered" ? toset(["0"]) : []

  owners      = ["aws-marketplace"]
  most_recent = true
  filter {
    name   = "name"
    values = ["*0c922525-51c4-4b64-94ec-744291c05c1c*"]
  }
}

data "aws_ami" "byol" {
  for_each = var.create && var.license_type == "byol" ? toset(["0"]) : []

  owners      = ["aws-marketplace"]
  most_recent = true
  filter {
    name   = "name"
    values = ["*109cd06c-210a-4fa4-839b-708683c66dc6*"]
  }
}

locals {
  controller          = { "aviatrix-controller" = var.vpc_public_subnets[0] }
  controller_ha       = var.enable_ha && length(var.vpc_public_subnets) > 1 ? { "aviatrix-controller-ha" = var.vpc_public_subnets[1] } : {}
  enabled_controllers = merge(local.controller, local.controller_ha)

  ami = var.license_type == "metered" ? data.aws_ami.metered["0"] : data.aws_ami.byol["0"]
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "controller" {
  count       = var.create ? 1 : 0
  name        = local.module_prefix
  tags        = local.tags
  description = format("%s-%s", var.desc_prefix, "Aviatrix Controller Security Group")

  vpc_id = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "controller_ingress" {
  count             = var.create ? 1 : 0
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.incoming_ssl_cidr
  security_group_id = aws_security_group.controller[0].id
}

resource "aws_security_group_rule" "controller_egress" {
  count             = var.create ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.controller[0].id
}

resource "aws_eip" "controllers" {
  for_each = var.create ? local.enabled_controllers : {}

  vpc = true
}

resource "aws_eip_association" "controllers" {
  for_each = local.enabled_controllers

  instance_id   = aws_instance.controllers[each.key].id
  allocation_id = aws_eip.controllers[each.key].id
}

resource "aws_network_interface" "controllers" {
  for_each = local.enabled_controllers
  tags = merge(local.tags, {
    Name = format("%s-%s : %s", local.stage_prefix, " interface", each.key)
  })

  subnet_id       = each.value
  security_groups = [aws_security_group.controller[0].id]
}

resource "aws_instance" "controllers" {
  for_each = local.enabled_controllers
  tags = merge(local.tags, {
    Name = format("%s-%s", local.stage_prefix, each.key)
  })

  ami                     = local.ami.image_id
  instance_type           = var.instance_type
  key_name                = var.key_pair
  iam_instance_profile    = var.aviatrix_iam_role_ec2_name
  disable_api_termination = var.termination_protection

  network_interface {
    network_interface_id = aws_network_interface.controllers[each.key].id
    device_index         = 0
  }

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
  }

  lifecycle {
    ignore_changes = [
      ami
    ]
  }
}

# Generate and write password
resource "random_password" "admin_password" {
  length      = 16
  min_upper   = 4
  min_lower   = 4
  min_numeric = 4
  min_special = 4

  keepers = {
    instance_id = aws_instance.controllers["aviatrix-controller"].id
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

# SSM Parameters

module "parameters_controller" {
  source      = "git::https://github.com/gravicore/terraform-gravicore-modules.git//aws/parameters?ref=0.32.0"
  providers   = { aws = "aws" }
  create      = var.create && var.create_parameters
  namespace   = var.namespace
  environment = var.environment
  stage       = var.stage
  tags        = local.tags

  write_parameters = {
    "/${local.stage_prefix}/${var.name}-admin-username" = { value = local.admin_username,
    description = "The administrator's username for the Aviatrix Controller" }
    "/${local.stage_prefix}/${var.name}-admin-email" = { value = var.admin_email,
    description = "The administrator's email address that will be used for password recovery as well as for notifications from the Controller" }
    "/${local.stage_prefix}/${var.name}-admin-password" = { value = random_password.admin_password.result, type = "SecureString",
    description = "The administrator's password for the Aviatrix Controller" }
    "/${local.stage_prefix}/${var.name}-access-account-name" = { value = local.access_account_name,
    description = "Access Account Name of the Avaitrix Controller" }
    "/${local.stage_prefix}/${var.name}-customer-license-id" = { value = var.customer_license_id, type = "SecureString",
    description = "The customer license ID is required if using a BYOL controller" }
    "/${local.stage_prefix}/${var.name}-ami" = { value = jsonencode(local.ami),
    description = "Map of AMI used for the Aviatrix Controller" }
    "/${local.stage_prefix}/${var.name}-private-ip" = { value = aws_instance.controllers["aviatrix-controller"].private_ip,
    description = "The private IP address of the AWS EC2 instance created for the Aviatrix Controller" }
    "/${local.stage_prefix}/${var.name}-public-ip" = { value = aws_instance.controllers["aviatrix-controller"].public_ip,
    description = "The public IP address of the AWS EC2 instance created for the Aviatrix Controller" }
    "/${local.stage_prefix}/${var.name}-ha-private-ip" = { value = aws_instance.controllers["aviatrix-controller"].private_ip,
    description = "The private IP address of the AWS EC2 instance created for the HA Aviatrix Controller" }
    "/${local.stage_prefix}/${var.name}-ha-public-ip" = { value = aws_instance.controllers["aviatrix-controller"].public_ip,
    description = "The public IP address of the AWS EC2 instance created for the HA Aviatrix Controller" }
    "/${local.stage_prefix}/${var.name}s" = { value = jsonencode(aws_instance.controllers),
    description = "Map of the provisioned Aviatrix Controllers" }
  }
}

# Outputs

output "aviatrix_controller_admin_username" {
  description = "The administrator's username for the Aviatrix Controller"
  value       = local.admin_username
}

output "aviatrix_controller_admin_email" {
  description = "The administrator's email address that will be used for password recovery as well as for notifications from the Controller"
  value       = var.admin_email
}

output "aviatrix_controller_admin_password" {
  description = "The administrator's password for the Aviatrix Controller"
  sensitive   = true
  value       = random_password.admin_password.result
}

output "aviatrix_controller_access_account_name" {
  description = "Access Account Name of the Avaitrix Controller"
  value       = local.access_account_name
}

output "aviatrix_controller_customer_license_id" {
  description = "The customer license ID is required if using a BYOL controller"
  sensitive   = true
  value       = var.customer_license_id
}

output "aviatrix_controller_ami" {
  description = "Map of AMI used for the Aviatrix Controller"
  value       = local.ami
}

output "aviatrix_controller_private_ip" {
  description = "The private IP address of the AWS EC2 instance created for the Aviatrix Controller"
  value       = aws_instance.controllers["aviatrix-controller"].private_ip
}

output "aviatrix_controller_public_ip" {
  description = "The public IP address of the AWS EC2 instance created for the Aviatrix Controller"
  value       = aws_instance.controllers["aviatrix-controller"].public_ip
}

output "aviatrix_controller_ha_private_ip" {
  description = "The private IP address of the AWS EC2 instance created for the HA Aviatrix Controller"
  value       = lookup(aws_instance.controllers, "aviatrix-controller-ha", "private_ip")
}

output "aviatrix_controller_ha_public_ip" {
  description = "The public IP address of the AWS EC2 instance created for the HA Aviatrix Controller"
  value       = lookup(aws_instance.controllers, "aviatrix-controller-ha", "public_ip")
}

output "aviatrix_controllers" {
  description = "Map of the provisioned Aviatrix Controllers"
  value       = aws_instance.controllers
}
