#IAM role - role logging
data "aws_iam_policy_document" "logging" {
  statement {
    actions   = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]
    resources = ["*"]
  }
}

#IAM role - flow log
data "aws_iam_policy_document" "vpc_flow_logging" {
  statement {
    actions   = ["sts:AssumeRole"]
    principals {
        type = "Service",
        identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "logging" {
  name        = "${var.name_prefix}-logging"
  description = "Role for logging resources"
  assume_role_policy = "${data.aws_iam_policy_document.vpc_flow_logging.json}"
}

resource "aws_iam_role_policy" "logging" {
  name = "${var.name_prefix}-logging"
  role = "${aws_iam_role.logging.id}"
  policy = "${data.aws_iam_policy_document.logging.json}"
}
