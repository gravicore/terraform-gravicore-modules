# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

###############################################
#######Variables for Lambda Configuration#######

variable "pre_sign_up" {
  type        = string
  default     = null
  description = "A pre-registration AWS Lambda trigger"
}

variable "pre_authentication" {
  type        = string
  default     = null
  description = "A pre-authentication AWS Lambda trigger"
}

variable "custom_message" {
  type        = string
  default     = null
  description = "A custom Message AWS Lambda trigger"
}

variable "post_authentication" {
  type        = string
  default     = null
  description = "A post-authentication AWS Lambda trigger"
}

variable "post_confirmation" {
  type        = string
  default     = null
  description = "A post-confirmation AWS Lambda trigger"
}

variable "define_auth_challenge" {
  type        = string
  default     = null
  description = "Defines the authentication challenge"
}

variable "create_auth_challenge" {
  type        = string
  default     = null
  description = "The ARN of the lambda creating an authentication challenge"
}

variable "verify_auth_challenge_response" {
  type        = string
  default     = null
  description = "Verifies the authentication challenge response"
}

variable "user_migration" {
  type        = string
  default     = null
  description = "The user migration Lambda config type"
}

variable "pre_token_generation" {
  type        = bool
  default     = null
  description = "Allow to customize identity token claims before token generation"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

# Lambda IAM

resource "aws_iam_role" "cognito_lambda" {
  count = var.create ? 1 : 0
  name  = "${local.module_prefix}-lambda-service"
  tags  = local.tags
  # path = "/service-role/"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "",
    "Effect": "Allow",
    "Principal": {
      "Service": "lambda.amazonaws.com"
    },
    "Action": "sts:AssumeRole"
  }]
}
POLICY
}

data "aws_iam_policy_document" "cognito_lambda" {
  count = var.create ? 1 : 0

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    actions   = ["iam:UpdateAssumeRolePolicy"]
    resources = ["arn:aws:iam::${var.account_id}:role/${local.module_prefix}-auth"]
  }

  statement {
    actions   = ["iam:UpdateAssumeRolePolicy"]
    resources = ["arn:aws:iam::${var.account_id}:role/${local.module_prefix}-unauth"]
  }
}

resource "aws_iam_role_policy" "cognito_lambda" {
  count = var.create ? 1 : 0
  name  = "${local.module_prefix}-lambda-access"

  role   = aws_iam_role.cognito_lambda[0].name
  policy = data.aws_iam_policy_document.cognito_lambda[0].json
}
