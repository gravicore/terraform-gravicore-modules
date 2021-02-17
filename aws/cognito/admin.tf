# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

####################################################
#######Variables for Admin Create User Config#######

variable admin_allow_admin_create_user_only {
  type        = bool
  description = "Set to true if only the administrator is allowed to create user profiles. Set false if users can sign themselves up via an app."
  default     = true
}

variable admin_temporary_password_validity_days {
  type        = number
  description = "The temporary password expiration limit, in days, after which the password is no longer usable"
  default     = 7
}

##Variable for Invite Message template (inside of Admin Create User Config)
variable admin_email_message {
  type        = string
  description = "The message template for email messages. Must contain {username} and {####} placeholder, for username and temporary password, respectively"
  default     = "Your username is {username} and temporary password is {####}"
}

variable admin_email_subject {
  type        = string
  description = "The subject line for email messages"
  default     = "Your temporary password for {####}"
}

variable admin_sms_message {
  type        = string
  description = "The messagetemplate for SMS messages. Must contain {username} and {####} placeholder, for username and temporary password, respectively"
  default     = "Your username is {username} and temporary password is {####}. If you do not log in within 7 days you'll need a new invite."
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

# User import service role

resource "aws_iam_role" "cognito_import_users" {
  count = var.create ? 1 : 0
  name  = "${local.module_prefix}-import-users-service"
  tags  = local.tags
  # path = "/service-role/"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "cognito-idp.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

data "aws_iam_policy_document" "cognito_import_users" {
  count = var.create ? 1 : 0

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:/aws/cognito/*"]
  }
}

resource "aws_iam_role_policy" "cognito_import_users" {
  count = var.create ? 1 : 0
  name  = "${local.module_prefix}-import-users-access"

  role   = aws_iam_role.cognito_import_users[0].id
  policy = data.aws_iam_policy_document.cognito_import_users[0].json
}
