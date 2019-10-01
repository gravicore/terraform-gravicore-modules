# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "organization_enable_default_service_control_policies" {
  type        = bool
  default     = true
  description = "List of recommended recommended default policies to deploy"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

# Having to use individual resources  with depend_on instead of a
# for_each resource because parallel deployment causes errors

resource "aws_organizations_policy" "protect_account" {
  count = var.create && var.organization_enable_default_service_control_policies ? 1 : 0

  name        = "grv-protect-account"
  description = "Denies the modification of the account contacts & settings via the Billing Portal and My Account Page"
  type        = "SERVICE_CONTROL_POLICY"
  content     = file("${path.module}/policies/protect-account.json")
}

resource "aws_organizations_policy" "protect_cloudtrail" {
  count      = var.create && var.organization_enable_default_service_control_policies ? 1 : 0
  depends_on = [aws_organizations_policy.protect_account]

  name        = "grv-protect-cloudtrail"
  description = "Deny deletion, update, or stopping of cloudtrail"
  type        = "SERVICE_CONTROL_POLICY"
  content     = file("${path.module}/policies/protect-cloudtrail.json")
}

resource "aws_organizations_policy" "protect_cloudwatch" {
  count      = var.create && var.organization_enable_default_service_control_policies ? 1 : 0
  depends_on = [aws_organizations_policy.protect_cloudtrail]

  name        = "grv-protect-cloudwatch"
  description = "Deny altering of cloudwatch"
  type        = "SERVICE_CONTROL_POLICY"
  content     = file("${path.module}/policies/protect-cloudwatch.json")
}

resource "aws_organizations_policy" "protect_flow_logs" {
  count      = var.create && var.organization_enable_default_service_control_policies ? 1 : 0
  depends_on = [aws_organizations_policy.protect_cloudwatch]

  name        = "grv-protect-flow-logs"
  description = "Deny deletion of flow logs"
  type        = "SERVICE_CONTROL_POLICY"
  content     = file("${path.module}/policies/protect-flow-logs.json")
}

resource "aws_organizations_policy" "protect_kms" {
  count      = var.create && var.organization_enable_default_service_control_policies ? 1 : 0
  depends_on = [aws_organizations_policy.protect_flow_logs]

  name        = "grv-protect-kms"
  description = "Deny ability to delete KMS keys"
  type        = "SERVICE_CONTROL_POLICY"
  content     = file("${path.module}/policies/protect-kms.json")
}

resource "aws_organizations_policy" "protect_organization" {
  count      = var.create && var.organization_enable_default_service_control_policies ? 1 : 0
  depends_on = [aws_organizations_policy.protect_kms]

  name        = "grv-protect-organization"
  description = "Deny ability to leave organization"
  type        = "SERVICE_CONTROL_POLICY"
  content     = file("${path.module}/policies/protect-organization.json")
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "organization_service_control_policies" {
  value = distinct([
    { name        = aws_organizations_policy.protect_account[0].name
      description = aws_organizations_policy.protect_account[0].description
      type        = aws_organizations_policy.protect_account[0].type
      content     = aws_organizations_policy.protect_account[0].content
    },
    { name        = aws_organizations_policy.protect_cloudtrail[0].name
      description = aws_organizations_policy.protect_cloudtrail[0].description
      type        = aws_organizations_policy.protect_cloudtrail[0].type
      content     = aws_organizations_policy.protect_cloudtrail[0].content
    },
    { name        = aws_organizations_policy.protect_cloudwatch[0].name
      description = aws_organizations_policy.protect_cloudwatch[0].description
      type        = aws_organizations_policy.protect_cloudwatch[0].type
      content     = aws_organizations_policy.protect_cloudwatch[0].content
    },
    { name        = aws_organizations_policy.protect_flow_logs[0].name
      description = aws_organizations_policy.protect_flow_logs[0].description
      type        = aws_organizations_policy.protect_flow_logs[0].type
      content     = aws_organizations_policy.protect_flow_logs[0].content
    },
    { name        = aws_organizations_policy.protect_kms[0].name
      description = aws_organizations_policy.protect_kms[0].description
      type        = aws_organizations_policy.protect_kms[0].type
      content     = aws_organizations_policy.protect_kms[0].content
    },
    { name        = aws_organizations_policy.protect_organization[0].name
      description = aws_organizations_policy.protect_organization[0].description
      type        = aws_organizations_policy.protect_organization[0].type
      content     = aws_organizations_policy.protect_organization[0].content
    },
  ])
  description = "A map of deployed service control policies"
}
