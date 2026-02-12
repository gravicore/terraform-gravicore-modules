# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "ssm_policy_name" {
  type        = string
  default     = "AmazonSSMManagedInstanceCore"
  description = "The policy for Amazon EC2 Role to enable AWS Systems Manager service core functionality."
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_iam_instance_profile" "ec2_profile" {
  count = var.create ? 1 : 0
  name  = local.module_prefix
  role  = concat(aws_iam_role.role.*.name, [""])[0]
}

data "aws_iam_policy_document" "assume_role" {
  count = var.create ? 1 : 0
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy" "instance_profile_policy" {
  name = var.ssm_policy_name
}

resource "aws_iam_role" "ec2_role" {
  count              = var.create ? 1 : 0
  name               = local.module_prefix
  path               = "/"
  assume_role_policy = concat(data.aws_iam_policy_document.assume_role.*.json, [""])[0]
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  count      = var.create ? 1 : 0
  role       = concat(aws_iam_role.ec2_role.*.name, [""])[0]
  policy_arn = var.ssm_policy_name
}

resource "aws_iam_instance_profile" "ec2_profile" {
  count = var.create ? 1 : 0
  name  = local.module_prefix
  role  = concat(aws_iam_role.ec2_role.*.name, [""])[0]
}

# ----------------------------------------------------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------------------------------------------------

output "instance_profile_arn" {
  value = concat(aws_iam_instance_profile.ec2_profile.*.arn, [""])[0]
}

output "instance_profile_name" {
  value = concat(aws_iam_instance_profile.ec2_profile.*.name, [""])[0]
}
