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

  statement {
    effect    = "Deny"
    actions   = ["*"]
    resources = ["arn:aws:iam::*:role/OrganizationAccountAccessRole"]
  }

  statement {
    effect  = "Deny"
    actions = ["*"]
    resources = [
      "arn:aws:s3:::*-terraform-state",
      "arn:aws:s3:::*-terraform-state/*"
    ]
  }
}

resource "aws_iam_policy" "billing_view_access" {
  count  = var.create ? 1 : 0
  name   = join(var.delimiter, [var.namespace, "billing", "view", "access"])
  policy = data.aws_iam_policy_document.billing_view_access.json
}

# Group
resource "aws_iam_group" "billing_viewers" {
  count = var.create && var.create_iam_groups && lookup(var.create_iam_groups_mapping, "billing-viewers", false) ? 1 : 0
  name  = join(var.delimiter, [var.namespace, "billing", "viewers"])
  path  = "/"
}

resource "aws_iam_group_policy_attachment" "billing_viewers" {
  count      = var.create && var.create_iam_groups && lookup(var.create_iam_groups_mapping, "billing-viewers", false) ? 1 : 0
  group      = aws_iam_group.billing_viewers[0].name
  policy_arn = aws_iam_policy.billing_view_access[0].arn
}

# Role

resource "aws_iam_role" "billing_viewer" {
  count = var.create && var.allow_gravicore_access ? 1 : 0
  name  = join(var.delimiter, [var.namespace, "billing", "viewer"])
  tags  = local.tags

  assume_role_policy   = data.template_file.assume_role_policy.rendered
  max_session_duration = var.role_max_session_duration
}

resource "aws_iam_role_policy_attachment" "billing_viewer" {
  count      = var.create && var.allow_gravicore_access ? 1 : 0
  role       = aws_iam_role.billing_viewer[0].name
  policy_arn = aws_iam_policy.billing_view_access[0].arn
}

# ----------------------------------------------------------------------------------------------------------------------
# Gravicore Access
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "gravicore_billing_viewer" {
  count = var.create && var.allow_gravicore_access ? 1 : 0
  name  = "gravicore-billing-viewer"
  tags  = local.tags

  assume_role_policy   = data.template_file.gravicore_assume_role_policy.rendered
  max_session_duration = var.role_max_session_duration
}

resource "aws_iam_role_policy_attachment" "gravicore_billing_viewer" {
  count      = var.create && var.allow_gravicore_access ? 1 : 0
  role       = aws_iam_role.gravicore_billing_viewer[0].name
  policy_arn = aws_iam_policy.billing_view_access[0].arn
}
