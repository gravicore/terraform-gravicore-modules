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

# SSM Parameters

module "parameters_key_pair" {
  source      = "git::https://github.com/gravicore/terraform-gravicore-modules.git//aws/parameters?ref=0.20.0"
  providers   = { aws = "aws" }
  create      = var.create
  namespace   = var.namespace
  environment = var.environment
  stage       = var.stage
  tags        = local.tags

  write_parameters = {
    "/${local.stage_prefix}/${var.name}-key-pair-private-pem" = { value = module.ssh_key_pair_private.private_key_pem, type = "SecureString",
    description = "Private SSH Key for EC2 Instances in private VPC Subnets" }
    "/${local.stage_prefix}/${var.name}-key-pair-private-pub" = { value = module.ssh_key_pair_private.public_key_openssh, type = "SecureString",
    description = "Public SSH Key for EC2 Instances in private VPC Subnets" }
    "/${local.stage_prefix}/${var.name}-key-pair-public-pem" = { value = module.ssh_key_pair_public.private_key_pem, type = "SecureString",
    description = "Private SSH Key for EC2 Instances in public VPC Subnets" }
    "/${local.stage_prefix}/${var.name}-key-pair-public-pub" = { value = module.ssh_key_pair_public.public_key_openssh, type = "SecureString",
    description = "Public SSH Key for EC2 Instances in public VPC Subnets" }
  }
}

# Outputs

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

output "vpc_key_pair_private_pub" {
  description = "Public SSH Key for EC2 Instances in private VPC Subnets"
  value       = var.create ? module.ssh_key_pair_private.public_key_openssh : null
  sensitive   = true
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

output "vpc_key_pair_public_pub" {
  description = "Public SSH Key for EC2 Instances in public VPC Subnets"
  value       = var.create ? module.ssh_key_pair_public.public_key_openssh : null
  sensitive   = true
}
