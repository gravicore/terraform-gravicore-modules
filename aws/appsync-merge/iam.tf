locals {
  name = substr(local.module_prefix, 0, 64)
}

resource "aws_iam_role" "this" {
  count = var.create ? 1 : 0
  name  = local.name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "appsync.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "this" {
  count = var.create ? 1 : 0
  name  = local.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      Resource = ["arn:aws:logs:*:*:*"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  count      = var.create ? 1 : 0
  role       = concat(aws_iam_role.this.*.name, [""])[0]
  policy_arn = concat(aws_iam_policy.this.*.arn, [""])[0]
}

resource "aws_iam_role_policy" "this" {
  count = var.create ? 1 : 0
  name  = local.name
  role  = concat(aws_iam_role.this.*.id, [""])[0]
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "lambda:*"
      Resource = var.graphql.target.lambda
    }]
  })
}
