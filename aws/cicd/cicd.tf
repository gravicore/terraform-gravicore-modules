# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "parameter_store_key_arn" {
  type        = string
  default     = ""
  description = "KMS key arn used for secure strings"
}

variable "cicd_elevated_policy_allow" {
  type    = "list"
  default = ["*"]
}

variable "cicd_elevated_policy_deny" {
  type    = "list"
  default = []
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "elevated" {
  statement {
    actions   = var.cicd_elevated_policy_allow
    resources = ["*"]
  }

  statement {
    effect    = length(var.cicd_elevated_policy_deny) > 0 ? "Deny" : "Allow"
    actions   = length(var.cicd_elevated_policy_deny) > 0 ? var.cicd_elevated_policy_deny : var.cicd_elevated_policy_allow
    resources = ["*"]
  }

  statement {
    effect    = "Deny"
    actions   = ["*"]
    resources = ["arn:aws:iam::*:role/OrganizationAccountAccessRole"]
  }
}

resource "aws_iam_policy" "elevated" {
  count = var.create ? 1 : 0
  name  = join(var.delimiter, [var.namespace, "elevated", "access"])

  policy = data.aws_iam_policy_document.elevated.json
}

resource "aws_iam_user" "elevated" {
  count = var.create ? 1 : 0
  name  = "${local.module_prefix}-elevated-access"

  tags = local.tags
}

resource "aws_iam_user_policy_attachment" "elevated" {
  count      = var.create ? 1 : 0
  user       = aws_iam_user.elevated[0].name
  policy_arn = aws_iam_policy.elevated[0].arn
}

resource "aws_iam_access_key" "elevated" {
  count = var.create ? 1 : 0
  user  = aws_iam_user.elevated[0].name
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_ssm_parameter" "service_access_key_id" {
  count       = var.create ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-elevated-access-key-id"
  description = format("%s %s", var.desc_prefix, "CICD Elevated service account Access Key ID")

  type      = "SecureString"
  value     = aws_iam_access_key.elevated[0].id
  overwrite = true
  tags      = local.tags
}

resource "aws_ssm_parameter" "service_access_key_secret" {
  count       = var.create ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-elevated-access-key-secret"
  description = format("%s %s", var.desc_prefix, "CICD Elevated service account Secret Access Key")

  type      = "SecureString"
  value     = aws_iam_access_key.elevated[0].secret
  overwrite = true
  tags      = local.tags
}