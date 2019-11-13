# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "create_cognito_service_user" {
  type        = bool
  default     = true
  description = "Creates a read only service user for congito"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_iam_user" "cognito" {
  count = var.create && var.create_cognito_service_user ? 1 : 0
  name  = "${local.module_prefix}-access"

  tags = local.tags
}

resource "aws_iam_access_key" "cognito" {
  count = var.create && var.create_cognito_service_user ? 1 : 0
  user  = "${aws_iam_user.cognito[0].name}"
}

resource "aws_iam_user_policy" "cognito_read" {
  count = var.create && var.create_cognito_service_user ? 1 : 0
  name  = "${local.module_prefix}-read-only"
  user  = "${aws_iam_user.cognito[0].name}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cognito-identity:Describe*",
                "cognito-identity:Get*",
                "cognito-identity:List*",
                "cognito-idp:Describe*",
                "cognito-idp:AdminGet*",
                "cognito-idp:AdminList*",
                "cognito-idp:List*",
                "cognito-idp:Get*",
                "cognito-sync:Describe*",
                "cognito-sync:Get*",
                "cognito-sync:List*",
                "iam:ListOpenIdConnectProviders",
                "iam:ListRoles",
                "sns:ListPlatformApplications"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_ssm_parameter" "service-access-key" {
  count       = "${var.create ? 1 : 0}"
  name        = "/${local.stage_prefix}/${var.name}-service-access-key"
  description = "Cognito service account access key"

  type      = "SecureString"
  value     = aws_iam_access_key.cognito[0].id
  overwrite = true
  tags      = local.tags
}

resource "aws_ssm_parameter" "service-secret-key" {
  count       = "${var.create ? 1 : 0}"
  name        = "/${local.stage_prefix}/${var.name}-service-secret-key"
  description = "Cognito service account secret key"

  type      = "SecureString"
  value     = aws_iam_access_key.cognito[0].secret
  overwrite = true
  tags      = local.tags
}