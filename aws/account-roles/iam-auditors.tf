# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "auditor_policy_allow" {
  type    = "list"
  default = ["*"]
}

variable "auditor_policy_deny" {
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

data "aws_iam_policy_document" "auditor" {
  statement {
    actions   = var.auditor_policy_allow
    resources = ["*"]
  }

  statement {
    effect    = "Deny"
    actions   = var.auditor_policy_deny
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

resource "aws_iam_policy" "auditor" {
  name = "${var.namespace}-auditor-access"

  policy = data.aws_iam_policy_document.auditor.json
}

# Group

resource "aws_iam_group" "auditors" {
  name = "${var.namespace}-auditors"
  path = "/"
}

resource "aws_iam_group_policy_attachment" "auditors" {
  group      = aws_iam_group.auditors.name
  policy_arn = aws_iam_policy.auditor.arn
}

resource "aws_iam_group_policy_attachment" "auditors_read_only" {
  group      = aws_iam_group.auditors.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Role

resource "aws_iam_role" "auditor" {
  name = "${var.namespace}-auditor"
  tags = local.tags

  assume_role_policy   = data.template_file.assume_role_policy.rendered
  max_session_duration = var.role_max_session_duration
}

resource "aws_iam_role_policy_attachment" "auditor" {
  role       = aws_iam_role.auditor.name
  policy_arn = aws_iam_policy.auditor.arn
}

resource "aws_iam_role_policy_attachment" "auditor_read_only" {
  role       = aws_iam_role.auditor.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# ----------------------------------------------------------------------------------------------------------------------
# Gravicore Access
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "gravicore_auditor" {
  count = "${var.allow_gravicore_access ? 1 : 0}"
  name  = "grv-auditor"
  tags  = local.tags

  assume_role_policy   = data.template_file.gravicore_assume_role_policy.rendered
  max_session_duration = var.role_max_session_duration
}

resource "aws_iam_role_policy_attachment" "gravicore_auditor" {
  count = "${var.allow_gravicore_access ? 1 : 0}"

  role       = aws_iam_role.gravicore_auditor[0].name
  policy_arn = aws_iam_policy.auditor.arn
}

resource "aws_iam_role_policy_attachment" "gravicore_auditor_read_only" {
  count = "${var.allow_gravicore_access ? 1 : 0}"

  role       = aws_iam_role.gravicore_auditor[0].name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
