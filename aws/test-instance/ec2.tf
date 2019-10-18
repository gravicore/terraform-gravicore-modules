# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC that the instance security group belongs to"
}

variable "vpc_subnets" {
  type        = list(string)
  description = "VPC Subnets the instance is launched in"
}

variable "ssh_key_pair" {
  type        = string
  description = "SSH key pair to be provisioned on the instance"
}

variable "instance_type" {
  type        = string
  default     = "t2.nano"
  description = ""
}

variable "ingress_cidr_block" {
  type        = string
  default     = "10.0.0.0/8"
  description = ""
}

variable "assign_eip_address" {
  type        = bool
  default     = false
  description = "Assign an Elastic IP address to the instance"
}

variable "associate_public_ip_address" {
  type        = bool
  default     = false
  description = "Associate a public IP address with the instance"
}

variable "dns_zone_name" {
  type        = string
  default     = ""
  description = "The DNS zone name to "
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

module "ec2_sg" {
  source      = "terraform-aws-modules/security-group/aws//modules/ssh"
  version     = "3.1.0"
  create      = var.create
  name        = replace("${local.module_prefix}-test", "-", var.delimiter)
  description = join(" ", list(var.desc_prefix, "Test SSH Instance"))
  tags        = local.tags

  vpc_id              = var.vpc_id
  ingress_cidr_blocks = [var.ingress_cidr_block]

  ingress_with_cidr_blocks = [
    {
      from_port   = -1
      to_port     = -1
      protocol    = "icmp"
      description = "All ICMP - IPv4"
      cidr_blocks = var.ingress_cidr_block
    },
  ]
}

# Test EC2 instance
module "ec2" {
  source           = "git::https://github.com/cloudposse/terraform-aws-ec2-instance.git?ref=0.11.0"
  instance_enabled = var.create
  namespace        = ""
  stage            = ""
  name             = "${local.module_prefix}-test"
  tags             = local.tags

  ssh_key_pair = var.ssh_key_pair
  vpc_id       = var.vpc_id
  subnet       = var.vpc_subnets[0]

  instance_type                 = var.instance_type
  create_default_security_group = false
  security_groups               = [module.ec2_sg.this_security_group_id]
  # assign_eip_address            = var.assign_eip_address
  # associate_public_ip_address   = var.associate_public_ip_address
}

# resource "aws_route53_record" "ec2" {
#   count    = var.create ? 1 : 0
#   name    = "test.${local.dns_zone_name}"

#   zone_id = aws_route53_zone.vpc[count.index].zone_id
#   type    = "A"
#   ttl     = "30"
#   records = [module.test_ssh_ec2_instance.private_ip]
# }

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "additional_eni_ids" {
  value       = module.ec2.additional_eni_ids
  description = "Map of ENI to EIP"
}

output "alarm" {
  value       = module.ec2.alarm
  description = "CloudWatch Alarm ID"
}

output "ebs_ids" {
  value       = module.ec2.ebs_ids
  description = "IDs of EBSs"
}

output "id" {
  value       = module.ec2.id
  description = "Disambiguated ID of the instance"
}

output "primary_network_interface_id" {
  value       = module.ec2.primary_network_interface_id
  description = "primary_network_interface_id"
}

output "private_dns" {
  value       = module.ec2.private_dns
  description = "Private DNS of instance"
}

output "private_ip" {
  value       = module.ec2.private_ip
  description = "Private IP of instance"
}

output "public_dns" {
  value       = module.ec2.public_dns
  description = "Public DNS of instance (or DNS of EIP)"
}

output "public_ip" {
  value       = module.ec2.public_ip
  description = "Public IP of instance (or EIP)"
}

output "role" {
  value       = module.ec2.role
  description = "Name of AWS IAM Role associated with the instance"
}

output "security_group_ids" {
  value       = module.ec2.security_group_ids
  description = "IDs on the AWS Security Groups associated with the instance"
}

output "ssh_key_pair" {
  value       = module.ec2.ssh_key_pair
  description = "Name of the SSH key pair provisioned on the instance"
}
