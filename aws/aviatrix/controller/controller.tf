# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "vpc_id" {
  type        = string
  description = "The VPC ID where the Controller will be installed"
}

variable "vpc_public_subnets" {
  type        = list(string)
  description = "The public subnet IDs where the Controller instance will reside."
}

variable "key_pair" {
  type        = string
  description = "The name of the AWS Key Pair (required when building an AWS EC2 instance)."
}

variable "aviatrix_role_ec2_name" {
  type        = string
  default     = "aviatrix-role-ec2"
  description = "The name of the aviatrix-ec2-role IAM role"
}

variable "instance_type" {
  type        = string
  default     = "t2.large"
  description = "The instance size for the Aviatrix controller instance"
}

variable "root_volume_size" {
  type        = number
  default     = null
  description = "The size of the hard disk for the controller instance"
}

variable "root_volume_type" {
  type        = string
  default     = "standard"
  description = "The type of the hard disk for the controller instance, Default value is `standard`"
}

variable "incoming_ssl_cidr" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "The CIDR to be allowed for HTTPS(port 443) access to the controller"
}

variable "license_type" {
  type        = string
  default     = "metered"
  description = "The license type for the Aviatrix controller. Valid values are `metered`, `BYOL`"
}

variable "termination_protection" {
  type        = bool
  default     = false
  description = "Whether termination protection is enabled for the controller"
}

variable "enable_ha" {
  type        = bool
  default     = false
  description = "Enable HA mode for the Aviatrix Controller"
}

locals {
  controller          = { "aviatrix-controller" = var.vpc_public_subnets[0] }
  controller_ha       = var.enable_ha && length(var.vpc_public_subnets) > 1 ? { "aviatrix-controller-ha" = var.vpc_public_subnets[1] } : {}
  enabled_controllers = merge(local.controller, local.controller_ha)

  images_metered = {
    us-east-1      = "ami-087b5ab4feb053b4b"
    us-east-2      = "ami-0bc1db3a5b89c6aef"
    us-west-1      = "ami-0a928ae10544ec78e"
    us-west-2      = "ami-0f5b26bac60280d69"
    ca-central-1   = "ami-031442f061af55923"
    eu-central-1   = "ami-0cf0c16d58a50f19b"
    eu-west-1      = "ami-0301c0164e6deb6df"
    eu-west-2      = "ami-04b5c38db962b3c13"
    eu-west-3      = "ami-0a11977b030622939"
    eu-north-1     = "ami-be961dc0"
    ap-east-1      = "ami-05b4cf74"
    ap-southeast-1 = "ami-02ae4a694e26953b2"
    ap-southeast-2 = "ami-06773bff73422d61d"
    ap-northeast-1 = "ami-048dff200571b34fd"
    ap-northeast-2 = "ami-0cb08d1ebcce1495f"
    ap-south-1     = "ami-09b9ca158a576fa9f"
    sa-east-1      = "ami-0f23734bcd9d53cd8"
  }
  images_byol = {
    us-east-1      = "ami-02465f499ff5092e1"
    us-east-2      = "ami-0861f8a0e35a19b0b"
    us-west-1      = "ami-0cf70ae96639f0057"
    us-west-2      = "ami-0d1499f297ecddea6"
    ca-central-1   = "ami-08ca66ca024bbce49"
    eu-central-1   = "ami-0f27d29114cb3e116"
    eu-west-1      = "ami-08d86496a8dcb9d33"
    eu-west-2      = "ami-001bdb44b4e47313a"
    eu-west-3      = "ami-01838788ed74ad98d"
    eu-north-1     = "ami-b2f378cc"
    ap-east-1      = "ami-9a552eeb"
    ap-southeast-1 = "ami-0a9c6a012c943b907"
    ap-southeast-2 = "ami-0e4d20f09c0318644"
    ap-northeast-1 = "ami-0971c3882816c1bc4"
    ap-northeast-2 = "ami-0d5e9b905bf30d2d3"
    ap-south-1     = "ami-0971c3882816c1bc4"
    sa-east-1      = "ami-0696240d0fc2ecc53"
    us-gov-west-1  = "ami-a9afe8c8"
  }
  ami_id = "${var.license_type == "metered" ? local.images_metered[var.aws_region] : local.images_byol[var.aws_region]}"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

# module "controller" {
#   source      = "git::https://github.com/AviatrixSystems/terraform-modules.git//aviatrix-controller-build?ref=terraform_0.12"
#   name_prefix = local.module_prefix

#   vpc                    = var.vpc_id
#   subnet                 = var.vpc_public_subnets[0]
#   keypair                = var.key_pair
#   ec2role                = var.aviatrix_role_ec2_name
#   instance_type          = var.instance_type
#   root_volume_size       = var.root_volume_size
#   root_volume_type       = var.root_volume_type
#   incoming_ssl_cidr      = var.incoming_ssl_cidr
#   type                   = var.license_type
#   termination_protection = var.termination_protection
# }

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

  ami                     = local.ami_id
  instance_type           = var.instance_type
  key_name                = var.key_pair
  iam_instance_profile    = var.aviatrix_role_ec2_name
  disable_api_termination = var.termination_protection

  network_interface {
    network_interface_id = aws_network_interface.controllers[each.key].id
    device_index         = 0
  }

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "controller_private_ip" {
  value       = aws_instance.controllers["aviatrix-controller"].private_ip
  description = "The private IP address of the AWS EC2 instance created for the Aviatrix Controller"
}

output "controller_public_ip" {
  value       = aws_instance.controllers["aviatrix-controller"].public_ip
  description = "The public IP address of the AWS EC2 instance created for the Aviatrix Controller"
}

output "controller_ha_private_ip" {
  value       = lookup(aws_instance.controllers, "aviatrix-controller-ha", "private_ip")
  description = "The private IP address of the AWS EC2 instance created for the HA Aviatrix Controller"
}

output "controller_ha_public_ip" {
  value       = lookup(aws_instance.controllers, "aviatrix-controller-ha", "public_ip")
  description = "The public IP address of the AWS EC2 instance created for the HA Aviatrix Controller"
}

output "controllers" {
  value       = aws_instance.controllers
  description = "Map of the provisioned Aviatrix Controllers"
}

# data "aws_ami" "aviatrix_controller" {
#   owners = ["aws-marketplace"]

#   most_recent = true
#   filter {
#     name   = "name"
#     values = ["*0c922525-51c4-4b64-94ec-744291c05c1c*"]
#   }
# }

# owner_id = "591182166581"
# data "aws_ami_ids" "aviatrix_controllers" {
#   owners = [data.aws_ami.aviatrix_controller.owner_id]
# }

# output "controller_ami_ids" {
#   value       = data.aws_ami_ids.aviatrix_controllers.ids
#   description = "List of Aviatrix Controller AMI IDs"
# }
