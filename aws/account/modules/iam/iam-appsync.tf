# IAM role - appsync
data "aws_iam_policy_document" "appsync" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com",
        "appsync.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "appsync" {
  name        = "${var.name_prefix}-appsync"
  description = "Role that UI will utilize for Lambda and Appsync"

  assume_role_policy = data.aws_iam_policy_document.appsync.json
}

resource "aws_iam_role_policy_attachment" "appsync" {
  role       = aws_iam_role.appsync.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

