# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "developer_policy_allow" {
  type    = "list"
  default = ["*"]
}

variable "developer_policy_deny" {
  type = "list"
  default = [
    "iam:Add*",
    "iam:Attach*",
    "iam:Change*",
    "iam:Create*",
    "iam:Deactivate*",
    "iam:Delete*",
    "iam:Detach*",
    "iam:Enable*",
    "iam:Put*",
    "iam:Remove*",
    "iam:Reset*",
    "iam:Resync*",
    "iam:Set*",
    "iam:Tag*",
    "iam:Untag*",
    "iam:Update*",
    "iam:Upload*",
  ]
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "developer" {
  statement {
    actions   = var.developer_policy_allow
    resources = ["*"]
  }

  statement {
    effect    = "Deny"
    actions   = var.developer_policy_deny
    resources = ["*"]
  }

  statement {
    effect    = "Deny"
    actions   = ["*"]
    resources = ["arn:aws:iam::*:role/OrganizationAccountAccessRole"]
  }

  statement {
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::*-terraform-state",
      "arn:aws:s3:::*-terraform-state/*"
    ]
  }
}

resource "aws_iam_policy" "developer" {
  name = "${var.namespace}-developer-access"

  policy = data.aws_iam_policy_document.developer.json
}

# Group

resource "aws_iam_group" "developers" {
  name = "${var.namespace}-developers"
  path = "/"
}

resource "aws_iam_group_policy_attachment" "developers" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.developer.arn
}

# Role

resource "aws_iam_role" "developer" {
  name = "${var.namespace}-developer"
  tags = local.tags

  assume_role_policy   = data.template_file.assume_role_policy.rendered
  max_session_duration = var.role_max_session_duration
}

resource "aws_iam_role_policy_attachment" "developer" {
  role       = aws_iam_role.developer.name
  policy_arn = aws_iam_policy.developer.arn
}

# ----------------------------------------------------------------------------------------------------------------------
# Gravicore Access
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "gravicore_developer" {
  count = "${var.allow_gravicore_access ? 1 : 0}"
  name  = "grv-developer"
  tags  = local.tags

  assume_role_policy   = data.template_file.gravicore_assume_role_policy.rendered
  max_session_duration = var.role_max_session_duration
}

resource "aws_iam_role_policy_attachment" "gravicore_developer" {
  count = "${var.allow_gravicore_access ? 1 : 0}"

  role       = aws_iam_role.gravicore_developer[0].name
  policy_arn = aws_iam_policy.developer.arn
}
