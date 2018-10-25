# Organization
output "organization-arn" {
  description = "arn of the organization"
  value       = "${element(concat(aws_organizations_organization.organization.*.arn, list("")), 0)}"
}

output "organization-id" {
  description = "Identifier of the organization"
  value       = "${element(concat(aws_organizations_organization.organization.*.id, list("")), 0)}"
}

output "organization-master-account_arn" {
  description = "ARN of the master account"
  value       = "${element(concat(aws_organizations_organization.organization.*.master_account_arn, list("")), 0)}"
}

output "organization-master-account-email" {
  description = "Email address of the master account"
  value       = "${element(concat(aws_organizations_organization.organization.*.master_account_email, list("")), 0)}"
}

output "organization-master-account-id" {
  description = "Identifier of the master account"
  value       = "${element(concat(aws_organizations_organization.organization.*.master_account_id, list("")), 0)}"
}

output "policy-account-id" {
  description = "The unique identifier of the account policy"
  value       = "${element(concat(aws_organizations_policy.account.*.id, list("")), 0)}"
}

output "policy-account-arn" {
  description = "The arn of the account policy"
  value       = "${element(concat(aws_organizations_policy.account.*.arn, list("")), 0)}"
}

output "policy-cloudtrail-id" {
  description = "The unique identifier of the cloudtrail policy"
  value       = "${element(concat(aws_organizations_policy.cloudtrail.*.id, list("")), 0)}"
}

output "policy-cloudtrail-arn" {
  description = "The arn of the cloudtrail policy"
  value       = "${element(concat(aws_organizations_policy.cloudtrail.*.arn, list("")), 0)}"
}

output "policy-cloudwatch-id" {
  description = "The unique identifier of the cloudwatch policy"
  value       = "${element(concat(aws_organizations_policy.cloudwatch.*.id, list("")), 0)}"
}

output "policy-cloudwatch-arn" {
  description = "The arn of the cloudwatch policy"
  value       = "${element(concat(aws_organizations_policy.cloudwatch.*.arn, list("")), 0)}"
}

output "policy-flow-logs-id" {
  description = "The unique identifier of the flow logs policy"
  value       = "${element(concat(aws_organizations_policy.flow-logs.*.id, list("")), 0)}"
}

output "policy-flow-logs-arn" {
  description = "The arn of the flow logs policy"
  value       = "${element(concat(aws_organizations_policy.flow-logs.*.arn, list("")), 0)}"
}

output "policy-kms-id" {
  description = "The unique identifier of the kms policy"
  value       = "${element(concat(aws_organizations_policy.kms.*.id, list("")), 0)}"
}

output "policy-kms-arn" {
  description = "The arn of the kms policy"
  value       = "${element(concat(aws_organizations_policy.kms.*.arn, list("")), 0)}"
}

output "policy-org-id" {
  description = "The unique identifier of the organization policy"
  value       = "${element(concat(aws_organizations_policy.org.*.id, list("")), 0)}"
}

output "policy-org-arn" {
  description = "The arn of the organization policy"
  value       = "${element(concat(aws_organizations_policy.org.*.arn, list("")), 0)}"
}
