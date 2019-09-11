# Organization
output "organization-arn" {
  description = "arn of the organization"
  value = element(
    concat(aws_organizations_organization.organization.*.arn, [""]),
    0,
  )
}

output "organization-id" {
  description = "Identifier of the organization"
  value = element(
    concat(aws_organizations_organization.organization.*.id, [""]),
    0,
  )
}

output "organization_accounts" {
  description = "List of organization accounts (including the master account), including elements for arn, email id and name."
  value       = aws_organizations_organization.organization[0].accounts
}

data "template_file" "organization_account_ids" {
  count    = length(aws_organizations_organization.organization[0].accounts)
  template = aws_organizations_organization.organization.0.accounts[count.index]["id"]
}

output "organization_account_ids" {
  description = "List of organization account IDs (including the master account)."
  value       = data.template_file.organization_account_ids.*.rendered
}

locals {
  organization_child_account_ids_sorted_filter_list = distinct(
    concat(
      [var.tags["MasterAccountID"]],
      data.template_file.organization_account_ids.*.rendered,
    ),
  )
}

output "organization_child_account_ids" {
  description = "List of organization account IDs (excluding the master account)."
  value = slice(
    local.organization_child_account_ids_sorted_filter_list,
    1,
    length(local.organization_child_account_ids_sorted_filter_list),
  )
}

output "organization-master-account_arn" {
  description = "ARN of the master account"
  value = element(
    concat(
      aws_organizations_organization.organization.*.master_account_arn,
      [""],
    ),
    0,
  )
}

output "organization-master-account-email" {
  description = "Email address of the master account"
  value = element(
    concat(
      aws_organizations_organization.organization.*.master_account_email,
      [""],
    ),
    0,
  )
}

output "organization-master-account-id" {
  description = "Identifier of the master account"
  value = element(
    concat(
      aws_organizations_organization.organization.*.master_account_id,
      [""],
    ),
    0,
  )
}

output "policy-account-id" {
  description = "The unique identifier of the account policy"
  value       = element(concat(aws_organizations_policy.account.*.id, [""]), 0)
}

output "policy-account-arn" {
  description = "The arn of the account policy"
  value       = element(concat(aws_organizations_policy.account.*.arn, [""]), 0)
}

output "policy-cloudtrail-id" {
  description = "The unique identifier of the cloudtrail policy"
  value       = element(concat(aws_organizations_policy.cloudtrail.*.id, [""]), 0)
}

output "policy-cloudtrail-arn" {
  description = "The arn of the cloudtrail policy"
  value       = element(concat(aws_organizations_policy.cloudtrail.*.arn, [""]), 0)
}

output "policy-cloudwatch-id" {
  description = "The unique identifier of the cloudwatch policy"
  value       = element(concat(aws_organizations_policy.cloudwatch.*.id, [""]), 0)
}

output "policy-cloudwatch-arn" {
  description = "The arn of the cloudwatch policy"
  value       = element(concat(aws_organizations_policy.cloudwatch.*.arn, [""]), 0)
}

output "policy-flow-logs-id" {
  description = "The unique identifier of the flow logs policy"

  value = element(concat(aws_organizations_policy.flow_logs.*.id, [""]), 0)
}

output "policy-flow-logs-arn" {
  description = "The arn of the flow logs policy"
  value       = element(concat(aws_organizations_policy.flow_logs.*.arn, [""]), 0)
}

output "policy-kms-id" {
  description = "The unique identifier of the kms policy"
  value       = element(concat(aws_organizations_policy.kms.*.id, [""]), 0)
}

output "policy-kms-arn" {
  description = "The arn of the kms policy"
  value       = element(concat(aws_organizations_policy.kms.*.arn, [""]), 0)
}

output "policy-org-id" {
  description = "The unique identifier of the organization policy"
  value       = element(concat(aws_organizations_policy.org.*.id, [""]), 0)
}

output "policy-org-arn" {
  description = "The arn of the organization policy"
  value       = element(concat(aws_organizations_policy.org.*.arn, [""]), 0)
}

