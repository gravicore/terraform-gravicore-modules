
resource "aws_iam_role" "s3_default" {
  count = var.create ? 1 : 0
  name  = "${local.module_prefix}-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      }
    }
  ]
}
EOF
}



resource "aws_iam_policy" "s3_default" {
  count  = var.create ? 1 : 0
  name   = "${local.module_prefix}-policy"
  policy = <<EOF
{
    "Statement": [
        {
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "sqs:sendMessage"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:logs:*:*:*",
                "${coalesce(join("", aws_sqs_queue.default[*].arn), "")}"
            ]
        }
    ],
    "Version": "2012-10-17"
}
EOF
}

resource "aws_iam_role_policy_attachment" "s3_default_policy_attachment" {
  count      = var.create ? 1 : 0
  role       = coalesce(join("", aws_iam_role.s3_default[*].name), "")
  policy_arn = coalesce(join("", aws_iam_policy.s3_default[*].arn), "")
}

resource "aws_iam_policy" "lambda_sqs_send_message_policy" {
  count       = var.create ? 1 : 0
  name        = "${local.module_prefix}-sqs-policy"
  description = "Allows Lambda function to send messages to SQS queue"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sqs:SendMessage"
        Resource = "arn:aws:sqs:${var.aws_region}:${var.account_id}:${local.stage_prefix}-bulk-upload-pool-servicer.fifo"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_send_message_policy_attachment" {
  count      = var.create ? 1 : 0
  role       = coalesce(join("", aws_iam_role.s3_default[*].name), "")
  policy_arn = coalesce(join("", aws_iam_policy.lambda_sqs_send_message_policy[*].arn), "")
}


