# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

###############################################
#######Variables for Lambda Configuration#######

variable pre_sign_up {
  type        = string
  default     = null
  description = "A pre-registration AWS Lambda trigger"
}

variable pre_authentication {
  type        = string
  default     = null
  description = "A pre-authentication AWS Lambda trigger"
}

variable custom_message {
  type        = string
  default     = null
  description = "A custom Message AWS Lambda trigger"
}

variable post_authentication {
  type        = string
  default     = null
  description = "A post-authentication AWS Lambda trigger"
}

variable post_confirmation {
  type        = string
  default     = null
  description = "A post-confirmation AWS Lambda trigger"
}

variable define_auth_challenge {
  type        = string
  default     = null
  description = "Defines the authentication challenge"
}

variable create_auth_challenge {
  type        = string
  default     = null
  description = "The ARN of the lambda creating an authentication challenge"
}

variable verify_auth_challenge_response {
  type        = string
  default     = null
  description = "Verifies the authentication challenge response"
}

variable user_migration {
  type        = string
  default     = null
  description = "The user migration Lambda config type"
}

variable pre_token_generation {
  type        = string
  default     = null
  description = "Allow to customize identity token claims before token generation"
}

locals {
  lambda_config = var.pre_sign_up != null || var.pre_authentication != null || var.custom_message != null || var.post_authentication != null || var.post_confirmation != null || var.define_auth_challenge != null || var.create_auth_challenge != null || var.verify_auth_challenge_response != null || var.user_migration != null || var.pre_token_generation != null ? { lambda_config = {
    pre_sign_up                    = var.pre_sign_up,
    pre_authentication             = var.pre_authentication,
    custom_message                 = var.custom_message,
    post_authentication            = var.post_authentication,
    post_confirmation              = var.post_confirmation,
    define_auth_challenge          = var.define_auth_challenge,
    create_auth_challenge          = var.create_auth_challenge,
    verify_auth_challenge_response = var.verify_auth_challenge_response,
    user_migration                 = var.user_migration,
    pre_token_generation           = var.pre_token_generation,
  } } : {}
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

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

# Lambda IAM

output "cognito_lambda_service_role_arn" {
  value       = aws_iam_role.cognito_lambda[0].arn
  description = "ARN of Cognito IAM service role used for lambda"
}
