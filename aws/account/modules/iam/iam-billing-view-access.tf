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
  name   = "${var.name_prefix}-billing-view-access"
  policy = "${data.aws_iam_policy_document.billing_view_access.json}"
}

resource "aws_iam_group" "billing_viewers" {
  name = "${var.name_prefix}-billing-viewers"
  path = "/"
}

resource "aws_iam_group_policy_attachment" "billing_viewers" {
  group      = "${aws_iam_group.billing_viewers.name}"
  policy_arn = "${aws_iam_policy.billing_view_access.arn}"
}


data "aws_iam_policy_document" "trusted_entities" {
  statement {
    actions   = ["sts:AssumeRole"]
    principals {
        type = "AWS",
        identifiers = ["${local.aws_trusted_entities}"]
    }
  }
  statement {
    actions   = ["sts:AssumeRoleWithSAML"]
    principals {
        type = "Federated",
        identifiers = ["${local.federated_trusted_entities}"]
    }
  }
}

resource "aws_iam_role" "billing_viewer" {
  count = "${var.allow_gravicore_access ? 1 : 0}"
  name  = "${var.name_prefix}-billing-viewer"
  assume_role_policy = "${data.template_file.assume_role_policy.rendered}"
}

resource "aws_iam_role_policy_attachment" "billing_viewer" {
  count = "${var.allow_gravicore_access ? 1 : 0}"
  role       = "${aws_iam_role.billing_viewer.name}"
  policy_arn = "${aws_iam_policy.billing_view_access.arn}"
}
