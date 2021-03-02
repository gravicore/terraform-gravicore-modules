############################################
#######Variable for SMS Configuration#######

resource "random_uuid" "sms_sns_external_id" {
  count = var.create && var.mfa_configuration != "OFF" ? 1 : 0
}

resource "aws_ssm_parameter" "sms_sns_external_id" {
  count       = var.create && var.mfa_configuration != "OFF" ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-sms-sns-external-id"
  description = "The Cognito SMS SNS external ID used in IAM role trust relationships"

  type      = "String"
  value     = random_uuid.sms_sns_external_id[0].result
  overwrite = true
  tags      = local.tags
}

variable sms_external_id {
  type        = string
  description = "he external ID used in IAM role trust relationships. For more information about using external IDs, see How to Use an External ID When Granting Access to Your AWS Resources to a Third Party"
  default     = ""
}

variable sms_sns_caller_arn {
  type        = string
  description = "The ARN of the Amazon SNS caller. This is usually the IAM role that you've given Cognito permission to assume"
  default     = ""
}

#########################################################
#######Variables for Verification Message Template#######

variable message_template_sms_message {
  type        = string
  description = "The SMS message template. Must contain the {####} placeholder. Conflicts with sms_verification_message argument."
  default     = ""
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

# SMS IAM

resource "aws_iam_role" "cognito_sms" {
  count = var.create && var.mfa_configuration != "OFF" ? 1 : 0
  name  = "${local.module_prefix}-sms-service-role"
  tags  = local.tags
  # path = "/service-role/"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "cognito-idp.amazonaws.com"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "${coalesce(var.sms_external_id, random_uuid.sms_sns_external_id[0].result)}"
        }
      }
    }
  ]
}
POLICY
}

data "aws_iam_policy_document" "cognito_sms" {
  count = var.create && var.mfa_configuration != "OFF" ? 1 : 0

  statement {
    actions = [
      "sns:publish"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "cognito_sms" {
  count = var.create && var.mfa_configuration != "OFF" ? 1 : 0
  name  = "${local.module_prefix}-sms-access"

  role   = aws_iam_role.cognito_sms[0].name
  policy = data.aws_iam_policy_document.cognito_sms[0].json
}
