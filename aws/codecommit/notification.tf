# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "notification_display_name" {
  description = "Name shown in confirmation emails"
  type        = string
  default     = "CodeCommit Notification"
}

variable "notification_email_addresses" {
  description = "Email address to send notifications to"
  type        = list(string)
  default     = []
}

variable "notification_protocol" {
  description = "SNS Protocol to use. email or email-json"
  type        = string
  default     = "email"
}

locals {
  notification_display_name = coalesce(
    var.notification_display_name,
    "${local.module_prefix}-${var.repository_name_suffix}",
  )
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

data "template_file" "cloudformation_sns_stack" {
  template = file("${path.module}/templates/sns_topic_email.cft.json.tpl")

  vars = {
    display_name = local.notification_display_name
    subscriptions = join(
      ",",
      formatlist(
        "{ \"Endpoint\": \"%s\", \"Protocol\": \"%s\"  }",
        var.notification_email_addresses,
        var.notification_protocol,
      ),
    )
  }
}

resource "aws_cloudformation_stack" "sns_topic_notification" {
  count = length(var.notification_email_addresses) == 0 ? 0 : 1
  name  = "${local.module_prefix}-${var.repository_name_suffix}"
  tags  = local.tags

  template_body = data.template_file.cloudformation_sns_stack.rendered
}

data "aws_iam_policy_document" "sns_topic_policy" {
  count = length(var.notification_email_addresses) == 0 ? 0 : 1

  statement {
    effect = "Allow"

    actions = [
      "SNS:GetTopicAttributes",
      "SNS:SetTopicAttributes",
      "SNS:AddPermission",
      "SNS:RemovePermission",
      "SNS:DeleteTopic",
      "SNS:Subscribe",
      "SNS:ListSubscriptionsByTopic",
      "SNS:Publish",
      "SNS:Receive",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [aws_cloudformation_stack.sns_topic_notification.0.outputs["arn"]]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        var.account_id,
      ]
    }
  }
}

resource "aws_sns_topic_policy" "default" {
  count = length(var.notification_email_addresses) == 0 ? 0 : 1

  arn    = aws_cloudformation_stack.sns_topic_notification.0.outputs["arn"]
  policy = data.aws_iam_policy_document.sns_topic_policy[0].json
}

resource "aws_cloudwatch_event_rule" "event_rule" {
  count       = length(var.notification_email_addresses) == 0 ? 0 : 1
  name        = "${local.module_prefix}-${var.repository_name_suffix}"
  description = "${var.desc_prefix}An Amazon CloudWatch Event rule has been created by AWS CodeCommit for the following repository: ${aws_codecommit_repository.repo.arn}."
  tags        = local.tags

  is_enabled = true

  event_pattern = <<PATTERN
{
  "source": [
    "aws.codecommit"
  ],
  "resources": [
    "${aws_codecommit_repository.repo.arn}"
  ],
  "detail-type": [
    "CodeCommit Pull Request State Change",
    "CodeCommit Comment on Pull Request",
    "CodeCommit Comment on Commit"
  ]
}
PATTERN

}

resource "aws_cloudwatch_event_target" "target" {
  count = length(var.notification_email_addresses) == 0 ? 0 : 1

  target_id  = "codecommit_notification"
  rule       = aws_cloudwatch_event_rule.event_rule[0].name
  arn        = aws_cloudformation_stack.sns_topic_notification.0.outputs["arn"]
  input_path = "$.detail.notificationBody"
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------
# output "notification_sns_topic_arn" {
#   description = "Email SNS topic ARN"
#   value       = "${length(var.notification_email_addresses) == 0 ? "" : join("", aws_cloudformation_stack.sns_topic_notification.outputs["arn"])}"
# }
