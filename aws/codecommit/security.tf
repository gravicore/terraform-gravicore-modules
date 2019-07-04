# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "developer_group" {
  description = "An existing IAM Group to attach the Developer policy permissions to"
  type        = "string"
  default     = ""
}

locals {
  developer_group = "${coalesce(var.developer_group, "${var.namespace}-developers")}"
}

variable "restrict_default_branch_actions" {
  description = "A set of action restrictions to apply to the repository's default branch."
  type        = "list"

  default = [
    "codecommit:GitPush",
    "codecommit:DeleteBranch",
    "codecommit:PutFile",
    "codecommit:MergePullRequestBySquash",
  ]
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

# Developer group restrictions

data "aws_iam_policy_document" "restrict_default_branch" {
  statement {
    effect = "Allow"

    actions = [
      "codecommit:*",
    ]

    resources = ["${aws_codecommit_repository.repo.arn}"]
  }

  statement {
    effect = "Deny"

    actions = "${var.restrict_default_branch_actions}"

    resources = ["${aws_codecommit_repository.repo.arn}"]

    condition {
      test     = "StringEqualsIfExists"
      variable = "codecommit:References"
      values   = ["refs/heads/${var.default_branch}"]
    }

    condition {
      test     = "Null"
      variable = "codecommit:References"
      values   = [false]
    }
  }
}

resource "aws_iam_policy" "restrict_default_branch" {
  name        = "${local.module_prefix}-${var.repository_name_suffix}"
  description = "${var.desc_prefix}Restricts the master branch of a CodeCommit repository"
  policy      = "${data.aws_iam_policy_document.restrict_default_branch.json}"
}

resource "aws_iam_group_policy_attachment" "restrict_default_branch_attach" {
  group      = "${local.developer_group}"
  policy_arn = "${aws_iam_policy.restrict_default_branch.arn}"
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "restrict_default_branch_policy_arn" {
  description = "The ARN assigned by AWS to the default branch policy."
  value       = "${aws_iam_policy.restrict_default_branch.arn}"
}
