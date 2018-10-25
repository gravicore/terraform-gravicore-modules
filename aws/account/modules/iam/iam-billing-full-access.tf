# IAM policy - BillingAdmin
data "aws_iam_policy_document" "billing_full_access" {
  statement {
    actions   = ["aws-portal:*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "billing_full_access" {
  name   = "${var.name_prefix}-billing-full-access"
  policy = "${data.aws_iam_policy_document.billing_full_access.json}"
}

resource "aws_iam_group" "billing_admins" {
  name = "${var.name_prefix}-billing-admins"
  path = "/"
}

resource "aws_iam_group_policy_attachment" "billing_admins" {
  group      = "${aws_iam_group.billing_admins.name}"
  policy_arn = "${aws_iam_policy.billing_full_access.arn}"
}
