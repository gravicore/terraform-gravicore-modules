# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "aviatrix_accounts" {
  type        = map
  default     = {}
  description = "A list of AWS Account IDs to add to the Aviatrix Controller"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aviatrix_account" "accounts" {
  for_each = var.aviatrix_accounts

  account_name = each.key
  cloud_type   = 1

  aws_iam            = true
  aws_account_number = each.value
  aws_role_app       = "arn:aws:iam::${each.value}:role/aviatrix-role-app"
  aws_role_ec2       = "arn:aws:iam::${each.value}:role/aviatrix-role-ec2"
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

# SSM Parameters

module "parameters_accounts" {
  source      = "git::https://github.com/gravicore/terraform-gravicore-modules.git//aws/parameters?ref=0.32.0"
  providers   = { aws = "aws" }
  create      = var.create && var.create_parameters
  namespace   = var.namespace
  environment = var.environment
  stage       = var.stage
  tags        = local.tags

  write_parameters = {
    "/${local.stage_prefix}/${var.name}" = { value = jsonencode({ for k, v in aviatrix_account.accounts : k => v.aws_account_number }),
    description = "Map of Aviatrix Accounts name and IDs" }
    "/${local.stage_prefix}/${var.name}_names" = { value = join(",", [for k, v in aviatrix_account.accounts : k]), type = "StringList",
    description = "List of Aviatrix Account names" }
    "/${local.stage_prefix}/${var.name}_ids" = { value = join(",", [for k, v in aviatrix_account.accounts : v.aws_account_number]), type = "StringList",
    description = "List of Aviatrix Account IDs" }
  }
}

# Outputs

output "aviatrix_accounts" {
  value       = aviatrix_account.accounts
  description = "Map of Aviatrix Accounts and attributes"
}

output "aviatrix_accounts_names" {
  value       = [for k, v in aviatrix_account.accounts : k]
  description = "List of Aviatrix Account names"
}

output "aviatrix_accounts_ids" {
  value       = [for k, v in aviatrix_account.accounts : v.aws_account_number]
  description = "List of Aviatrix Account IDs"
}
