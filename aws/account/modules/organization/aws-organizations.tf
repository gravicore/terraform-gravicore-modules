# AWS Organization Feature set, either ALL(Enables cross account management) or Consolidated Billing only
resource "aws_organizations_organization" "organization" {
  count = "${var.create_organization ? 1 : 0}"

  feature_set = "${var.organization_feature_set}"
}

# AWS Organziation Policy
resource "aws_organizations_policy" "account" {
  count = "${var.create_default_policies ? 1 : 0}"

  name        = "grv-protect-account"
  description = "Denies the modification of the account contacts & settings via the Billing Portal and My Account Page"
  type        = "SERVICE_CONTROL_POLICY"
  content     = "${file("${path.module}/policies/aws-policy-protect-account.json")}"
}

resource "aws_organizations_policy" "cloudtrail" {
  count = "${var.create_default_policies ? 1 : 0}"

  name        = "grv-protect-cloudtrail"
  description = "Deny deletion, update, or stopping of cloudtrail"
  type        = "SERVICE_CONTROL_POLICY"
  content     = "${file("${path.module}/policies/aws-policy-protect-cloudtrail.json")}"
}

resource "aws_organizations_policy" "cloudwatch" {
  count = "${var.create_default_policies ? 1 : 0}"

  name        = "grv-protect-cloudwatch"
  description = "Deny altering of cloudwatch"
  type        = "SERVICE_CONTROL_POLICY"
  content     = "${file("${path.module}/policies/aws-policy-protect-cloudwatch.json")}"
}

resource "aws_organizations_policy" "flow-logs" {
  count = "${var.create_default_policies ? 1 : 0}"

  name        = "grv-protect-flow-logs"
  description = "Deny deletion of flow-logs"
  type        = "SERVICE_CONTROL_POLICY"
  content     = "${file("${path.module}/policies/aws-policy-protect-flow-logs.json")}"
}

resource "aws_organizations_policy" "kms" {
  count = "${var.create_default_policies ? 1 : 0}"

  name        = "grv-deny-kms-deletion"
  description = "Deny ability to delete KMS keys"
  type        = "SERVICE_CONTROL_POLICY"
  content     = "${file("${path.module}/policies/aws-policy-deny-kms-deletion.json")}"
}

resource "aws_organizations_policy" "org" {
  count = "${var.create_default_policies ? 1 : 0}"

  name        = "grv-deny-leave-org"
  description = "Deny ability to leave organization"
  type        = "SERVICE_CONTROL_POLICY"
  content     = "${file("${path.module}/policies/aws-policy-deny-leave-org.json")}"
}
