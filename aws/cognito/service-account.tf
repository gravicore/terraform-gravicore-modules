# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable create_cognito_service_user {
  type        = bool
  default     = false
  description = "Creates a read only service user for congito"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_iam_user" "cognito" {
  count = var.create && var.create_cognito_service_user ? 1 : 0
  name  = join(var.delimiter, [local.module_prefix, "access"])

  tags = local.tags
}

resource "aws_iam_access_key" "cognito" {
  count = var.create && var.create_cognito_service_user ? 1 : 0
  user  = aws_iam_user.cognito[0].name
}


resource "aws_iam_policy" "cognito_read" {
  count = var.create && var.create_cognito_service_user ? 1 : 0
  name  = join(var.delimiter, [local.module_prefix, "read", "only"])

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

resource "aws_iam_group" "cognito_read" {
  count = var.create ? 1 : 0
  name  = join(var.delimiter, [local.module_prefix, "read", "only"])
  path  = "/"
}

resource "aws_iam_group_policy_attachment" "cognito_read" {
  count      = var.create ? 1 : 0
  group      = aws_iam_group.cognito_read[0].name
  policy_arn = aws_iam_policy.cognito_read[0].arn
}

resource "aws_iam_group_membership" "cognito_read" {
  count = var.create ? 1 : 0
  name  = join(var.delimiter, [local.module_prefix, "read", "only", "membership"])

  users = [
    aws_iam_user.cognito[0].name
  ]

  group = aws_iam_group.cognito_read[0].name
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_ssm_parameter" "service_access_key_id" {
  count       = var.create && var.create_cognito_service_user ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-service-access-key-id"
  description = format("%s %s", var.desc_prefix, "Cognito service account Access Key ID")

  type      = "SecureString"
  value     = aws_iam_access_key.cognito[0].id
  overwrite = true
  tags      = local.tags
}

resource "aws_ssm_parameter" "service_access_key_secret" {
  count       = var.create && var.create_cognito_service_user ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-service-access-key-secret"
  description = format("%s %s", var.desc_prefix, "Cognito service account Secret Access Key")

  type      = "SecureString"
  value     = aws_iam_access_key.cognito[0].secret
  overwrite = true
  tags      = local.tags
}