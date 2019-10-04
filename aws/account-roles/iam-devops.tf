# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "devop_policy_allow" {
  type    = "list"
  default = ["*"]
}

variable "devop_policy_deny" {
  type    = "list"
  default = []
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "devop" {
  statement {
    actions   = var.devop_policy_allow
    resources = ["*"]
  }

  statement {
    effect    = length(var.devop_policy_deny) > 0 ? "Deny" : "Allow"
    actions   = length(var.devop_policy_deny) > 0 ? var.devop_policy_deny : var.devop_policy_allow
    resources = ["*"]
  }

  statement {
    effect    = "Deny"
    actions   = ["*"]
    resources = ["arn:aws:iam::*:role/OrganizationAccountAccessRole"]
  }
}

resource "aws_iam_policy" "devop" {
  name = join(var.delimiter, [var.namespace, "devop", "access"])

  policy = data.aws_iam_policy_document.devop.json
}

# Group

resource "aws_iam_group" "devops" {
  name = join(var.delimiter, [var.namespace, "devops"])
  path = "/"
}

resource "aws_iam_group_policy_attachment" "devops" {
  group      = aws_iam_group.devops.name
  policy_arn = aws_iam_policy.devop.arn
}

# Role

resource "aws_iam_role" "devop" {
  name = join(var.delimiter, [var.namespace, "devop"])
  tags = local.tags

  assume_role_policy   = data.template_file.assume_role_policy.rendered
  max_session_duration = var.role_max_session_duration
}

resource "aws_iam_role_policy_attachment" "devop" {
  role       = aws_iam_role.devop.name
  policy_arn = aws_iam_policy.devop.arn
}

# ----------------------------------------------------------------------------------------------------------------------
# Gravicore Access
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "gravicore_devop" {
  count = var.allow_gravicore_access ? 1 : 0
  name  = "grv-devop"
  tags  = local.tags

  assume_role_policy   = data.template_file.gravicore_assume_role_policy.rendered
  max_session_duration = var.role_max_session_duration
}

resource "aws_iam_role_policy_attachment" "gravicore_devop" {
  count = var.allow_gravicore_access ? 1 : 0

  role       = aws_iam_role.gravicore_devop[0].name
  policy_arn = aws_iam_policy.devop.arn
}
