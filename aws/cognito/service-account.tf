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
  user  = "${aws_iam_user.cognito.name}"
}

resource "aws_iam_user_policy" "cognito_read" {
  count = var.create && var.create_cognito_service_user ? 1 : 0
  name  = "${local.module_prefix}-read-only"
  user  = "${aws_iam_user.cognito.name}"

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

module "parameters_cognito" {
  source      = "git::https://github.com/gravicore/terraform-gravicore-modules.git//aws/parameters?ref=0.20.0"
  providers   = { aws = "aws" }
  create      = var.create
  namespace   = var.namespace
  environment = var.environment
  stage       = var.stage
  tags        = local.tags

  write_parameters = {
    "/${local.stage_prefix}/${var.name}-service-access-key" = { value = aws_iam_access_key.cognito[0].id, type = "SecureString", description = "Cognito service account access key" }
    "/${local.stage_prefix}/${var.name}-service-secret-key" = { value = aws_iam_access_key.cognito[1].secret, type = "SecureString", description = "Cognito service account secret key" }
  }
}
