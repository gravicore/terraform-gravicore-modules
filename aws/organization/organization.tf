# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "organization_aws_service_access_principals" {
  type = list(string)
  default = [
    "aws-artifact-account-sync.amazonaws.com",
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "config-multiaccountsetup.amazonaws.com",
    "ds.amazonaws.com",
    "fms.amazonaws.com",
    "license-manager.amazonaws.com",
    "license-manager.member-account.amazonaws.com",
    "ram.amazonaws.com",
    "servicecatalog.amazonaws.com",
    "servicequotas.amazonaws.com",
    "sso.amazonaws.com",
  ]
  description = "List of AWS service principal names for which you want to enable integration with your organization. This is typically in the form of a URL, such as service-abbreviation.amazonaws.com. Organization must have feature_set set to ALL."
}

variable "organization_enabled_policy_types" {
  type        = list(string)
  default     = ["SERVICE_CONTROL_POLICY"]
  description = "List of Organizations policy types to enable in the Organization Root. Organization must have feature_set set to ALL."
}

variable "organization_feature_set" {
  type        = string
  default     = "ALL"
  description = "Specify 'ALL' (default) or 'CONSOLIDATED_BILLING'."
}

variable "organization_environments" {
  type        = list(string)
  default     = []
  description = "A list of environments to generate accounts from"
}

variable "organization_environments_email_format" {
  type        = string
  default     = "aws+%[2]s-%[3]s@%[1]s#example"
  description = "A string format to use when generate emails for environment accounts ([1] = Namespace, [2] = Environment, [3] = Stage)"
}

variable "organization_accounts" {
  type        = map
  default     = {}
  description = "A map of member accounts to create in the organization. Use this to manage a custom list of accounts, otherwise use `organization_environments` to dynamically generate accoutns from environments and stages."
}

variable "organization_default_iam_user_access_to_billing" {
  type        = string
  default     = null
  description = "If set to `ALLOW`, the new account enables IAM users to access account billing information if they have the required permissions. If set to `DENY`, then only the root user of the new account can access account billing information."
}

variable "organization_default_parent_id" {
  type        = string
  default     = null
  description = "Parent Organizational Unit ID or Root ID for the account. Defaults to the Organization default Root ID. A configuration must be present for this argument to perform drift detection."
}

variable "organization_default_role_name" {
  type        = string
  default     = null
  description = "The name of an IAM role that Organizations automatically preconfigures in the new member account. This role trusts the master account, allowing users in the master account to assume the role, as permitted by the master account administrator. The role has administrator permissions in the new member account."
}

variable "organization_default_stages" {
  type        = list(string)
  default     = ["dev", "stg", "prd"]
  description = "The default stages to deploy for each environment"
}

locals {
  environment_accounts = length(var.organization_environments) < 1 ? {} : { for p in setproduct(var.organization_environments, var.organization_default_stages) :
    join(var.delimiter, compact(concat([var.namespace], p))) =>
    {
      email                      = format(var.organization_environments_email_format, var.namespace, p[0], p[1])
      iam_user_access_to_billing = var.organization_default_iam_user_access_to_billing
      parent_id                  = var.organization_default_parent_id
      role_name                  = var.organization_default_role_name
    }
  }
  organization_accounts = merge(local.environment_accounts, var.organization_accounts)
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_organizations_organization" "organization" {
  count = var.create ? 1 : 0

  aws_service_access_principals = var.organization_aws_service_access_principals
  enabled_policy_types          = var.organization_enabled_policy_types
  feature_set                   = var.organization_feature_set
}

# Organization Accounts

resource "aws_organizations_account" "organization_accounts" {
  for_each = var.create ? local.organization_accounts : {}
  tags     = local.tags

  name  = each.key
  email = each.value.email

  iam_user_access_to_billing = lookup(each.value, "iam_user_access_to_billing", var.organization_default_iam_user_access_to_billing)
  parent_id                  = lookup(each.value, "parent_id", var.organization_default_parent_id)
  role_name                  = lookup(each.value, "role_name", var.organization_default_role_name)

  # There is no AWS Organizations API for reading role_name
  lifecycle {
    ignore_changes = [role_name]
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

# SSM Parameters

module "params" {
  source      = "../parameters"
  create      = var.create
  namespace   = var.namespace
  environment = var.environment
  stage       = var.stage
  tags        = local.tags

  write_parameters = {
    "/${local.stage_prefix}/${var.name}-id" = { value = aws_organizations_organization.organization[0].id,
    description = "Identifier of the organization" }
    "/${local.stage_prefix}/${var.name}-arn" = { value = aws_organizations_organization.organization[0].arn,
    description = "ARN of the organization" }
    "/${local.stage_prefix}/${var.name}-master-account-id" = { value = aws_organizations_organization.organization[0].master_account_id,
    description = "Identifier of the master account" }
    "/${local.stage_prefix}/${var.name}-accounts" = { value = jsonencode(aws_organizations_organization.organization[0].accounts),
    description = "List of organization accounts including the master account" }
    "/${local.stage_prefix}/${var.name}-account-ids" = { value = join(",", aws_organizations_organization.organization[0].accounts[*].id), type = "StringList",
    description = "A list of Organization account identifiers including the master account" }
    "/${local.stage_prefix}/${var.name}-non-master-accounts" = { value = jsonencode(aws_organizations_organization.organization[0].non_master_accounts),
    description = "List of organization accounts excluding the master account" }
    "/${local.stage_prefix}/${var.name}-non-master-account-ids" = { value = join(",", aws_organizations_organization.organization[0].non_master_accounts[*].id), type = "StringList",
    description = "A list of Organization account identifiers excluding the master account" }
  }
}

# Outputs

output "organization_id" {
  value       = aws_organizations_organization.organization[0].id
  description = "Identifier of the organization"
}

output "organization_arn" {
  value       = aws_organizations_organization.organization[0].arn
  description = "ARN of the organization"
}

output "organization_master_account_id" {
  description = "Identifier of the master account"
  value       = aws_organizations_organization.organization[0].master_account_id
}

output "organization_master_account_arn" {
  description = "ARN of the master account"
  value       = aws_organizations_organization.organization[0].master_account_arn
}

output "organization_master_account_email" {
  description = "Email address of the master account"
  value       = aws_organizations_organization.organization[0].master_account_email
}

output "organization_service_access_principals" {
  value       = aws_organizations_organization.organization[0].aws_service_access_principals
  description = "List of enabled AWS service principal names"
}

output "organization_accounts" {
  value       = aws_organizations_organization.organization[0].accounts
  description = "List of organization accounts including the master account"
}

output "organization_account_ids" {
  value       = aws_organizations_organization.organization[0].accounts[*].id
  description = "A list of Organization account identifiers including the master account"
}

output "organization_account_arns" {
  value       = aws_organizations_organization.organization[0].accounts[*].arn
  description = "A list of Organization account ARNs"
}

output "organization_non_master_accounts" {
  value       = aws_organizations_organization.organization[0].non_master_accounts
  description = "List of organization accounts excluding the master account"
}

output "organization_non_master_account_ids" {
  value       = aws_organizations_organization.organization[0].non_master_accounts[*].id
  description = "A list of Organization account identifiers excluding the master account"
}

output "organization_non_master_account_arns" {
  value       = aws_organizations_organization.organization[0].accounts[*].arn
  description = "A list of Organization account ARNs excluding the master account"
}
