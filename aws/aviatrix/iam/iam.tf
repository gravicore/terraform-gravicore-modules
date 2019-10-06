# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "controller_account_id" {
  type        = string
  default     = ""
  description = "The Aviatrix Controller's AWS account ID"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

# Aviatrix EC2 Service Role

data "http" "assume_role" {
  count = var.create ? 1 : 0

  url = "https://s3-us-west-2.amazonaws.com/aviatrix-download/iam_assume_role_policy.txt"
  request_headers = {
    "Accept" = "application/json"
  }
}

resource "aws_iam_policy" "assume_role" {
  count       = var.create ? 1 : 0
  name        = "aviatrix-assume-role-policy"
  description = join(" ", [var.desc_prefix, "Policy for creating assume_role"])

  path   = "/"
  policy = "${data.http.assume_role[0].body}"
}

data "http" "ec2" {
  count = var.create ? 1 : 0

  url = "https://s3-us-west-2.amazonaws.com/aviatrix-download/IAM_access_policy_for_CloudN.txt"
  request_headers = {
    "Accept" = "application/json"
  }
}

resource "aws_iam_role" "ec2" {
  count       = var.create ? 1 : 0
  name        = "aviatrix-role-ec2"
  description = join(" ", [var.desc_prefix, "Aviatrix EC2 Service Role"])
  tags        = local.tags

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
         "Effect": "Allow",
         "Principal": {
           "Service": [
              "ec2.amazonaws.com"
           ]
         },
         "Action": [
           "sts:AssumeRole"
         ]
       }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ec2" {
  count = var.create ? 1 : 0

  role       = "${aws_iam_role.ec2[0].name}"
  policy_arn = "${aws_iam_policy.assume_role[0].arn}"
}

resource "aws_iam_instance_profile" "ec2" {
  count = var.create ? 1 : 0

  name = "${aws_iam_role.ec2[0].name}"
  role = "${aws_iam_role.ec2[0].name}"
}

# Aviatrix Application Role

locals {
  policy_primary = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": [
              "arn:aws:iam::${local.account_id}:root"
            ]
        },
        "Action": [
          "sts:AssumeRole"
        ]
      }
    ]
}
POLICY
  policy_cross   = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": [
              "arn:aws:iam::${var.controller_account_id}:root",
              "arn:aws:iam::${local.account_id}:root"
            ]
        },
        "Action": [
          "sts:AssumeRole"
        ]
      }
    ]
}
POLICY
}

resource "aws_iam_role" "app" {
  count       = var.create ? 1 : 0
  name        = "aviatrix-role-app"
  description = join(" ", [var.desc_prefix, "Aviatrix App Role"])
  tags        = local.tags

  assume_role_policy = "${var.controller_account_id == "" ? local.policy_primary : local.policy_cross}"
}

resource "aws_iam_policy" "app" {
  count       = var.create ? 1 : 0
  name        = "aviatrix-app-policy"
  description = join(" ", [var.desc_prefix, "Policy for Aviatrix Application"])

  policy = "${data.http.ec2[0].body}"
}

resource "aws_iam_role_policy_attachment" "app" {
  count = var.create ? 1 : 0

  role       = "${aws_iam_role.app[0].name}"
  policy_arn = "${aws_iam_policy.app[0].arn}"
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "account_id" {
  value       = local.account_id
  description = "The AWS account ID"
}

output "account_name" {
  value       = local.stage_prefix
  description = "The AWS account alias"
}

output "aviatrix_role_ec2_name" {
  value       = aws_iam_role.ec2[0].name
  description = "The ARN of the newly created Aviatrix IAM EC2 Role"
}

output "aviatrix_role_app_name" {
  value       = aws_iam_role.app[0].name
  description = "The name of the newly created Aviatrix IAM App Role"
}

output "aviatrix_role_ec2_arn" {
  value       = aws_iam_role.ec2[0].arn
  description = "The ARN of the newly created Aviatrix IAM EC2 Role"
}

output "aviatrix_role_app_arn" {
  value       = aws_iam_role.app[0].arn
  description = "The ARN of the newly created Aviatrix IAM App Role"
}
