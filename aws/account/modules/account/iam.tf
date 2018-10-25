#IAM role - log
resource "aws_iam_role" "logging" {
  name        = "${var.common_tags["application"]}_logging_svc"
  description = "Role for logging resources"

  assume_role_policy = "${file("${path.module}/policies/iam-flow-log.json")}"
}

resource "aws_iam_role_policy" "logging-policy" {
  name = "${var.common_tags["application"]}-logging-policy"
  role = "${aws_iam_role.logging.id}"

  policy = "${file("${path.module}/policies/iam-role-logging.json")}"
}

# IAM role - appsync
resource "aws_iam_role" "appsync" {
  name        = "${var.common_tags["application"]}_appsync_svc"
  description = "Role that UI will utilize for Lambda and Appsync"

  assume_role_policy = "${file("${path.module}/policies/iam-role-appsync.json")}"
}

resource "aws_iam_role_policy_attachment" "appsync-policy" {
  role       = "${aws_iam_role.appsync.name}"
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# IAM policy - BillingAdmin
data "aws_iam_policy_document" "billing_full_access" {
  statement {
    actions   = ["aws-portal:*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "billing_full_access" {
  name   = "BillingFullAccess"
  policy = "${data.aws_iam_policy_document.billing_full_access}"
}

# IAM policy - BillingReviewer
data "aws_iam_policy_document" "billing_view_access" {
  statement {
    actions = [
      "aws-portal:ViewPaymentMethods",
      "aws-portal:ViewAccount",
      "aws-portal:ViewBilling",
      "aws-portal:ViewUsage",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "billing_view_access" {
  name   = "BillingViewAccess"
  policy = "${data.aws_iam_policy_document.billing_view_access}"
}
