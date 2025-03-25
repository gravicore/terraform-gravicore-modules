locals {
  names = {
    default = substr("${local.module_prefix}-appsync", 0, 64)
    trusted = substr("${local.module_prefix}-trust", 0, 64)
  }
}

resource "aws_iam_role" "trust" {
  count = var.create ? 1 : 0
  name  = local.names.trusted

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "trust" {
  count = var.create ? 1 : 0
  name  = local.names.trusted
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

resource "aws_iam_role_policy_attachment" "trust" {
  count      = var.create ? 1 : 0
  role       = concat(aws_iam_role.trust.*.name, [""])[0]
  policy_arn = concat(aws_iam_policy.trust.*.arn, [""])[0]
}

resource "aws_iam_role_policy" "this" {
  count = var.create ? 1 : 0
  name  = local.names.default
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
