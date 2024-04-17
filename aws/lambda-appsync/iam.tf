
resource "aws_iam_role" "default" {
  name = "${locals.module_prefix}-lambda-role-policy"

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



resource "aws_iam_policy" "default" {
  name   = "${locals.module_prefix}-lambda-role-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_scan_notification_attach" {
  role       = aws_iam_role.default.name
  policy_arn = aws_iam_policy.default.arn
}

resource "aws_iam_role" "appsync_service_role" {
  name = "${local.module_prefix}-appsync-lambda-invoke-policy"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "appsync.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "appsync_lambda_invoke_policy" {
  name = "${local.module_prefix}-appsync-lambda-invoke-policy"
  role = aws_iam_role.appsync_service_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "lambda:*"
        Resource = "${aws_lambda_function.default.arn}"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "appsync_lambda_attach" {
  role       = aws_iam_role.appsync_service_role.name
  policy_arn = aws_iam_policy.appsync_lambda_invoke_policy.arn
}
