# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "kms_param_arn" {
  type        = string
  default     = "alias/parameter_store_key"
  description = "The ARN of a KMS key used to encrypt and decrypt SecretString values"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

# Create a default key/pair for public and private instances

module "ssh_key_pair_private" {
  source  = "mitchellh/dynamic-keys/aws"
  version = "2.0.0"

  name = "${local.module_prefix}-private"
  path = "${pathexpand("~/.ssh")}/${var.namespace}/${var.stage}"
}

module "ssh_key_pair_public" {
  source  = "mitchellh/dynamic-keys/aws"
  version = "2.0.0"

  name = "${local.module_prefix}-public"
  path = "${pathexpand("~/.ssh")}/${var.namespace}/${var.stage}"
}


# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

# Private

output "vpc_key_pair_private_name" {
  description = "Name of the private SSH Key for EC2 Instances in private VPC Subnets"
  value       = var.create ? module.ssh_key_pair_private.key_name : null
}

output "vpc_key_pair_private_pem" {
  description = "Private SSH Key for EC2 Instances in private VPC Subnets"
  value       = var.create ? module.ssh_key_pair_private.private_key_pem : null
  sensitive   = true
}

resource "aws_ssm_parameter" "parameter_key-pair-private-pem" {
  count       = var.create ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}_key-pair-private-pem"
  description = format("%s %s", var.desc_prefix, "Private SSH Key for EC2 Instances in private VPC Subnets")
  tags        = var.tags

  type   = "SecureString"
  key_id = data.aws_kms_key.kms["0"].key_id
  value  = module.ssh_key_pair_private.private_key_pem
}

output "vpc_key_pair_private_pub" {
  description = "Public SSH Key for EC2 Instances in private VPC Subnets"
  value       = var.create ? module.ssh_key_pair_private.public_key_openssh : null
  sensitive   = true
}

resource "aws_ssm_parameter" "parameter_key_pair_private_pub" {
  count       = var.create ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-key-pair-private-pub"
  description = format("%s %s", var.desc_prefix, "Public SSH Key for EC2 Instances in private VPC Subnets")
  tags        = var.tags

  type   = "SecureString"
  key_id = data.aws_kms_key.kms["0"].key_id
  value  = module.ssh_key_pair_private.public_key_openssh
}

# Public

output "vpc_key_pair_public_name" {
  description = "Name of the private SSH Key for EC2 Instances in public VPC Subnets"
  value       = var.create ? module.ssh_key_pair_public.key_name : null
}

output "vpc_key_pair_public_pem" {
  description = "Private SSH Key for EC2 Instances in public VPC Subnets"
  value       = var.create ? module.ssh_key_pair_public.private_key_pem : null
  sensitive   = true
}

resource "aws_ssm_parameter" "parameter_key_pair_public_pem" {
  count       = var.create ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-key-pair-public-pem"
  description = format("%s %s", var.desc_prefix, "Private SSH Key for EC2 Instances in public VPC Subnets")
  tags        = var.tags

  type   = "SecureString"
  key_id = data.aws_kms_key.kms["0"].key_id
  value  = module.ssh_key_pair_public.private_key_pem
}

output "vpc_key_pair_public_pub" {
  description = "Public SSH Key for EC2 Instances in public VPC Subnets"
  value       = var.create ? module.ssh_key_pair_public.public_key_openssh : null
  sensitive   = true
}

resource "aws_ssm_parameter" "parameter_key_pair_public_pub" {
  count       = var.create ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-key-pair-public-pub"
  description = format("%s %s", var.desc_prefix, "Public SSH Key for EC2 Instances in public VPC Subnets")
  tags        = var.tags

  type   = "SecureString"
  key_id = data.aws_kms_key.kms["0"].key_id
  value  = module.ssh_key_pair_public.public_key_openssh
}
