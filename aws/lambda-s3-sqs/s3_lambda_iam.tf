
resource "aws_iam_role" "s3_default" {
  name = "${local.module_prefix}-lambda-role-policy"

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
  name   = "${local.module_prefix}-lambda-role-policy"
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

resource "aws_iam_role_policy_attachment" "s3_default_policy_attachment" {
  role       = aws_iam_role.default.name
  policy_arn = aws_iam_policy.default.arn
}
