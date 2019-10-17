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

locals {
  ssh_secret_ssm_write = [
    {
      name        = "/${local.stage_prefix}/${var.name}-private-pem"
      value       = module.ssh_key_pair_private.private_key_pem
      type        = "SecureString"
      overwrite   = true
      description = join(" ", [var.desc_prefix, "Private SSH Key for EC2 Instances in private VPC Subnets"])
    },
    {
      name        = "/${local.stage_prefix}/${var.name}-private-pub"
      value       = module.ssh_key_pair_private.public_key_openssh
      type        = "SecureString"
      overwrite   = true
      description = join(" ", [var.desc_prefix, "Public SSH Key for EC2 Instances in private VPC Subnets"])
    },
    {
      name        = "/${local.stage_prefix}/${var.name}-public-pem"
      value       = module.ssh_key_pair_public.private_key_pem
      type        = "SecureString"
      overwrite   = true
      description = join(" ", [var.desc_prefix, "Private SSH Key for EC2 Instances in public VPC Subnets"])
    },
    {
      name        = "/${local.stage_prefix}/${var.name}-public-pub"
      value       = module.ssh_key_pair_public.public_key_openssh
      type        = "SecureString"
      overwrite   = true
      description = join(" ", [var.desc_prefix, "Public SSH Key for EC2 Instances in public VPC Subnets"])
    },
  ]

  # `ssh_secret_ssm_write_count` needs to be updated if `ssh_secret_ssm_write` changes
  ssh_secret_ssm_write_count = 4
}

resource "aws_ssm_parameter" "default" {
  count       = var.create ? local.ssh_secret_ssm_write_count : 0
  name        = local.ssh_secret_ssm_write[count.index].name
  tags        = local.tags
  description = local.ssh_secret_ssm_write[count.index].description

  type            = local.ssh_secret_ssm_write[count.index].type
  key_id          = local.ssh_secret_ssm_write[count.index].type == "SecureString" && length(var.kms_param_arn) > 0 ? var.kms_param_arn : ""
  value           = local.ssh_secret_ssm_write[count.index].value
  overwrite       = local.ssh_secret_ssm_write[count.index].overwrite
  allowed_pattern = lookup(local.ssh_secret_ssm_write[count.index], "allowed_pattern", "")
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

# Private

output "key_pair_private_name" {
  value       = var.create ? module.ssh_key_pair_private.key_name : null
  description = "Name of the private SSH Key for EC2 Instances in private VPC Subnets"
}

output "key_pair_private_param_pem" {
  value       = var.create ? "/${local.stage_prefix}/${var.name}-private-pem" : null
  description = "SSM Parameter name of the private SSH Key for EC2 Instances in private VPC Subnets"
}

output "key_pair_private_param_pub" {
  value       = var.create ? "/${local.stage_prefix}/${var.name}-private-pub" : null
  description = "SSM Parameter name of the public SSH Key for EC2 Instances in private VPC Subnets"
}

# Public

output "key_pair_public_key_name" {
  value       = var.create ? module.ssh_key_pair_public.key_name : null
  description = "Name of the private SSH Key for EC2 Instances in public VPC Subnets"
}

output "key_pair_public_param_pem" {
  value       = var.create ? "/${local.stage_prefix}/${var.name}-public-pem" : null
  description = "SSM Parameter name of the private SSH Key for EC2 Instances in public VPC Subnets"
}

output "key_pair_public_param_pub" {
  value       = var.create ? "/${local.stage_prefix}/${var.name}-public-pub" : null
  description = "SSM Parameter name of the public SSH Key for EC2 Instances in public VPC Subnets"
}
