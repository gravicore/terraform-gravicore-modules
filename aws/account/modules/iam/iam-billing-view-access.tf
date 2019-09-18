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
  policy = data.aws_iam_policy_document.billing_view_access.json
}

resource "aws_iam_group" "billing_viewers" {
  name = "${var.name_prefix}-billing-viewers"
  path = "/"
}

resource "aws_iam_group_policy_attachment" "billing_viewers" {
  group      = aws_iam_group.billing_viewers.name
  policy_arn = aws_iam_policy.billing_view_access.arn
}

data "aws_iam_policy_document" "trusted_entities" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "AWS"
      # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
      # force an interpolation expression to be interpreted as a list by wrapping it
      # in an extra set of list brackets. That form was supported for compatibility in
      # v0.11, but is no longer supported in Terraform v0.12.
      #
      # If the expression in the following list itself returns a list, remove the
      # brackets to avoid interpretation as a list of lists. If the expression
      # returns a single list item then leave it as-is and remove this TODO comment.
      identifiers = local.aws_trusted_entities
    }
  }
  statement {
    actions = ["sts:AssumeRoleWithSAML"]
    principals {
      type = "Federated"
      # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
      # force an interpolation expression to be interpreted as a list by wrapping it
      # in an extra set of list brackets. That form was supported for compatibility in
      # v0.11, but is no longer supported in Terraform v0.12.
      #
      # If the expression in the following list itself returns a list, remove the
      # brackets to avoid interpretation as a list of lists. If the expression
      # returns a single list item then leave it as-is and remove this TODO comment.
      identifiers = local.federated_trusted_entities
    }
  }
}

resource "aws_iam_role" "billing_viewer" {
  count              = var.allow_gravicore_access ? 1 : 0
  name               = "${var.name_prefix}-billing-viewer"
  assume_role_policy = data.template_file.assume_role_policy.rendered
}

resource "aws_iam_role_policy_attachment" "billing_viewer" {
  count      = var.allow_gravicore_access ? 1 : 0
  role       = aws_iam_role.billing_viewer[0].name
  policy_arn = aws_iam_policy.billing_view_access.arn
}

