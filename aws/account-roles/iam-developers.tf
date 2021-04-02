# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "developer_policy_allow" {
  type    = list(string)
  default = ["*"]
}

variable "developer_policy_deny" {
  type = list(string)
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
    effect    = length(var.developer_policy_deny) > 0 ? "Deny" : "Allow"
    actions   = length(var.developer_policy_deny) > 0 ? var.developer_policy_deny : var.developer_policy_allow
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
  count  = var.create ? 1 : 0
  name   = join(var.delimiter, [var.namespace, "developer", "access"])
  policy = data.aws_iam_policy_document.developer.json
}

# Group

resource "aws_iam_group" "developers" {
  count = var.create && var.create_iam_groups && lookup(var.create_iam_groups_mapping, "developers", false) ? 1 : 0
  name  = join(var.delimiter, [var.namespace, "developers"])
  path  = "/"
}

resource "aws_iam_group_policy_attachment" "developers" {
  count      = var.create && var.create_iam_groups && lookup(var.create_iam_groups_mapping, "developers", false) ? 1 : 0
  group      = aws_iam_group.developers[0].name
  policy_arn = aws_iam_policy.developer[0].arn
}

# Role

resource "aws_iam_role" "developer" {
  count = var.create ? 1 : 0
  name  = join(var.delimiter, [var.namespace, "developer"])
  tags  = local.tags

  assume_role_policy   = data.template_file.assume_role_policy.rendered
  max_session_duration = var.role_max_session_duration
}

resource "aws_iam_role_policy_attachment" "developer" {
  count      = var.create ? 1 : 0
  role       = aws_iam_role.developer[0].name
  policy_arn = aws_iam_policy.developer[0].arn
}

# ----------------------------------------------------------------------------------------------------------------------
# Gravicore Access
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "gravicore_developer" {
  count = var.create && var.allow_gravicore_access ? 1 : 0
  name  = "grv-developer"
  tags  = local.tags

  assume_role_policy   = data.template_file.gravicore_assume_role_policy.rendered
  max_session_duration = var.role_max_session_duration
}

resource "aws_iam_role_policy_attachment" "gravicore_developer" {
  count = var.create && var.allow_gravicore_access ? 1 : 0

  role       = aws_iam_role.gravicore_developer[0].name
  policy_arn = aws_iam_policy.developer[0].arn
}
