# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

locals {
  snowballs_locations = { for k, v in local.datasync_locations_s3 : k => v if lookup(v, "enable_snowball", false) }
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

# S3 buckets
# module "snowballs" {
#   enabled                  = var.create ? 1 : 0
#   source                   = "git::https://github.com/cloudposse/terraform-aws-s3-bucket.git?ref=master"
#   namespace                = ""
#   stage                    = ""
#   name                     = "${local.module-prefix}-"

#     allow_encrypted_uploads_only = true
# }

# S3 bucket policies
# {
#   "Version": "2012-10-17",
#   "Id": "PutObjPolicy",
#   "Statement": [
#     {
#       "Sid": "DenyIncorrectEncryptionHeader",
#       "Effect": "Deny",
#       "Principal": "*",
#       "Action": "s3:PutObject",
#       "Resource": "arn:aws:s3:::YourBucket/*",
#       "Condition": {
#         "StringNotEquals": {
#           "s3:x-amz-server-side-encryption": "AES256"
#         }
#       }
#     },
#     {
#       "Sid": "DenyUnEncryptedObjectUploads",
#       "Effect": "Deny",
#       "Principal": "*",
#       "Action": "s3:PutObject",
#       "Resource": "arn:aws:s3:::YourBucket/*",
#       "Condition": {
#         "Null": {
#           "s3:x-amz-server-side-encryption": "true"
#         }
#       }
#     }
#   ]
# }

# IAM user policies
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Effect": "Allow",
#             "Action": [
#                         "s3:ListBucket",
#                         "s3:GetBucketPolicy",
#                         "s3:GetBucketLocation",
#                         "s3:ListBucketMultipartUploads",
#                         "s3:ListAllMyBuckets",
#                         "s3:CreateBucket"
#             ],
#             "Resource": [
#                 "*"
#             ]
#         },
#         {
#             "Effect": "Allow",
#             "Action": [
#                         "kms:DescribeKey",
#                         "kms:ListAliases",
#                         "kms:ListKeys",
#                         "kms:CreateGrant"
#             ],
#             "Resource": [
#                 "*"
#             ]
#         },
#         {
#            "Effect": "Allow",
#            "Action": [
#                 "iam:AttachRolePolicy",
#                 "iam:CreatePolicy",
#                 "iam:CreateRole",
#                 "iam:ListRoles",
#                 "iam:ListRolePolicies",
#                 "iam:PutRolePolicy",
#                 "iam:PassRole"
#            ],
#            "Resource": [
#                 "*"
#            ]
#         },
#         {
#             "Effect": "Allow",
#             "Action": [
#                         "sns:CreateTopic",
#                         "sns:GetTopicAttributes",
#                         "sns:ListSubscriptionsByTopic",
#                         "sns:ListTopics",
#                         "sns:Subscribe",
#                         "sns:SetTopicAttributes"
#             ],
#             "Resource": [
#                 "*"
#             ]
#          },
#          {
#             "Effect": "Allow",
#             "Action": [
#                 "snowball:*",
#                 "importexport:*"
#             ],
#             "Resource": "*"
#         }
#     ]
# }

# IAM Snowball policies

resource "aws_iam_role" "snowballs" {
  for_each    = var.create && length(local.snowballs_locations) > 0 ? local.snowballs_locations : {}
  path        = "/${local.stage_prefix}/${var.name}/"
  name        = join("-", [local.module_prefix, "snowballs", each.key])
  description = join(" ", [var.desc_prefix, "Allows Snowball (${each.key}) to access S3 location"])
  tags        = local.tags

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "importexport.amazonaws.com"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "AWSIE"
        }
      }
    }
  ]
}
EOF
}

# Allow import policy
data "aws_iam_policy_document" "snowballs_import" {
  for_each = var.create && length(local.snowballs_locations) > 0 ? local.snowballs_locations : {}

  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:GetBucketPolicy",
      "s3:ListBucketMultipartUploads",
    ]
    resources = ["arn:aws:s3:::${each.value.s3_bucket}"]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
      "s3:PutObjectAcl",
      "s3:PutObject",
    ]
    resources = [
      "arn:aws:s3:::${each.value.s3_bucket}${each.value.subdirectory}*",
    ]
  }
}

resource "aws_iam_role_policy" "snowballs_import" {
  for_each = var.create && length(local.snowballs_locations) > 0 ? local.snowballs_locations : {}
  name     = join("-", [local.module_prefix, "snowball-import", each.key])

  role   = aws_iam_role.snowballs[each.key].id
  policy = data.aws_iam_policy_document.snowballs_import[each.key].json
}

# Allow export policy
data "aws_iam_policy_document" "snowballs_export" {
  for_each = var.create && length(local.snowballs_locations) > 0 ? local.snowballs_locations : {}

  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:GetBucketPolicy",
      "s3:ListBucket"
    ]
    resources = ["arn:aws:s3:::${each.value.s3_bucket}"]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "arn:aws:s3:::${each.value.s3_bucket}${each.value.subdirectory}*",
    ]
  }
}

resource "aws_iam_role_policy" "snowballs_export" {
  for_each = var.create && length(local.snowballs_locations) > 0 ? local.snowballs_locations : {}
  name     = join("-", [local.module_prefix, "snowball-export", each.key])

  role   = aws_iam_role.snowballs[each.key].id
  policy = data.aws_iam_policy_document.snowballs_export[each.key].json
}

# SNS notifications

# ----------------------------------------------------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------------------------------------------------

output "snowballs_locations" {
  description = "S3 bucket locations to grant Snowball access to"
  value = var.create && length(local.snowballs_locations) > 0 ? { for k, v in local.snowballs_locations : k =>
    merge(v,
      { snowball_iam_role_arn = aws_iam_role.snowballs[k].arn },
      { snowball_iam_policy_import_arn = aws_iam_role_policy.snowballs_import[k].id },
      { snowball_iam_policy_export_arn = aws_iam_role_policy.snowballs_export[k].id },
  ) } : null
}
