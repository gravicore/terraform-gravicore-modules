data "aws_iam_policy_document" "log_assume" {
  count = "${var.enabled == "true" ? 1 : 0}"

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "log" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "log" {
  count  = "${var.enabled == "true" ? 1 : 0}"
  name   = "${module.vpc_label.id}"
  role   = "${aws_iam_role.log.id}"
  policy = "${data.aws_iam_policy_document.log.json}"
}

resource "aws_iam_role" "log" {
  count              = "${var.enabled == "true" ? 1 : 0}"
  name               = "${module.vpc_label.id}"
  assume_role_policy = "${data.aws_iam_policy_document.log_assume.json}"
}
