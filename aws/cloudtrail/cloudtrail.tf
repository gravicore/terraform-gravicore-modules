# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "attributes" {
  type        = list(string)
  default     = []
  description = "Additional attributes (e.g. `1`)"
}

variable "access_log_prefix" {
  type        = string
  default     = "access-logs/"
  description = "Path of logs in S3 bucket"
}

variable "log_force_destroy" {
  type        = bool
  default     = false
  description = "Delete all objects from the bucket  so that the bucket can be destroyed without error (e.g. `true` or `false`)"
}

variable "log_lifecycle_prefix" {
  type        = string
  default     = ""
  description = "Prefix filter. Used to manage object lifecycle events"
}

variable "log_standard_transition_days" {
  type        = number
  default     = 30
  description = "Number of days to persist in the standard storage tier before moving to the glacier tier"
}

variable "log_glacier_transition_days" {
  type        = number
  default     = 60
  description = "Number of days after which to move the data to the glacier storage tier"
}

variable "log_expiration_days" {
  type        = number
  default     = 90
  description = "Number of days after which to expunge the objects"
}

variable "s3_bucket_versioning" {
  type        = bool
  default     = false
  description = "S3 bucket versioning enabled?"
}

variable "s3_bucket_access_logging" {
  type        = bool
  default     = true
  description = "Access logging of S3 buckets"
}

variable "access_log_bucket_name" {
  type        = string
  default     = null
  description = "bucket to write access logs to"
}

variable "s3_bucket_ssl_requests_only" {
  type        = bool
  description = "S3 bucket ssl requests only?"
  default     = false
}

variable "sse_algorithm" {
  type        = string
  default     = "AES256"
  description = "The server-side encryption algorithm to use. Valid values are `AES256` and `aws:kms`"
}

variable "kms_master_key_arn" {
  type        = string
  default     = ""
  description = "The AWS KMS master key ARN used for the `SSE-KMS` encryption. This can only be used when you set the value of `sse_algorithm` as `aws:kms`. The default aws/s3 AWS KMS master key is used if this element is absent while the `sse_algorithm` is `aws:kms`"
}

variable "vpc_id" {
  type        = string
  default     = null
  description = ""
}

variable "guardduty_detector_id" {
  type        = string
  default     = null
  description = ""
}

variable "flow_log_filter_pattern" {
  type        = string
  default     = null
  description = ""
}

variable "vpc_flow_log_group_name" {
  type        = string
  default     = null
  description = ""
}

variable "log_enable_glacier_transition" {
  type        = bool
  default     = false
  description = "Enables the transition to AWS Glacier which can cause unnecessary costs for huge amount of small files"
}

variable "enforce_secure_transport" {
  type        = bool
  default     = true
  description = "When enabled enforces secure transport connections to bucket"
}

variable "enable_org_writes" {
  type        = bool
  default     = false
  description = "When enabled allows all accounts cloudtrail logs to be writen in Org"
}

variable "sns_topic_name" {
  type        = string
  default     = ""
  description = "(Optional) Name of the Amazon SNS topic defined for notification of log file delivery. Specify the SNS topic ARN if it resides in another region"
}

variable "create_sns_topic" {
  type        = bool
  default     = false
  description = "(Optional) If true, creates SNS topic defined for log file delivery"
}

variable "create_s3_bucket" {
  type        = bool
  default     = true
  description = "description"
}

variable "s3_bucket_name" {
  type        = string
  default     = ""
  description = "description"
}

variable "is_multi_region_trail" {
  type        = bool
  default     = true
  description = "description"
}

variable "allowed_sns_subscription_accounts" {
  type        = list(string)
  default     = null
  description = "description"
}

locals {
  create_storage_bucket = var.create && var.create_s3_bucket && var.s3_bucket_name == ""
  create_sns_topic      = var.create && var.sns_topic_name == "" && var.create_sns_topic
}
# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

data "aws_organizations_organization" "default" {
  count = var.enable_org_writes ? 1 : 0
}

data "aws_iam_policy_document" "bucket" {
  count = local.create_storage_bucket ? 1 : 0
  statement {
    sid = "AWSCloudTrailAclCheck"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = [
      "s3:GetBucketAcl",
    ]
    resources = [
      "arn:aws:s3:::${local.module_prefix}-events",
    ]
  }

  statement {
    sid = "AWSCloudTrailWrite"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = [
      "s3:PutObject",
    ]
    resources = [
      "arn:aws:s3:::${local.module_prefix}-events/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"

      values = [
        "bucket-owner-full-control",
      ]
    }
  }

  dynamic "statement" {
    for_each = var.enforce_secure_transport ? [1] : []
    content {
      sid    = "EnforceSecureTransport"
      effect = "Deny"
      principals {
        type        = "AWS"
        identifiers = ["*"]
      }
      actions = [
        "s3:*",
      ]
      resources = [
        "arn:aws:s3:::${local.module_prefix}-events",
        "arn:aws:s3:::${local.module_prefix}-events/*",
      ]
      condition {
        test     = "Bool"
        variable = "aws:SecureTransport"

        values = [
          "false",
        ]
      }
    }
  }

  dynamic "statement" {
    for_each = var.enable_org_writes ? [1] : []
    content {
      sid    = "OrgCrossAccountWrite"
      effect = "Allow"
      principals {
        type        = "*"
        identifiers = ["*"]
      }
      actions = [
        "s3:PutObject",
        "s3:GetBucketAcl",
      ]
      resources = [
        "arn:aws:s3:::${local.module_prefix}-events",
        "arn:aws:s3:::${local.module_prefix}-events/*",
      ]
      condition {
        test     = "StringEquals"
        variable = "aws:PrincipalOrgID"

        values = [
          concat(data.aws_organizations_organization.default.*.id, [""])[0],
        ]
      }
    }
  }
}

resource "aws_s3_bucket" "default" {
  count  = local.create_storage_bucket ? 1 : 0
  bucket = join("-", [local.module_prefix, "events"])
  tags   = local.tags
}

resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  count  = local.create_storage_bucket ? 1 : 0
  bucket = concat(aws_s3_bucket.default.*.id, [""])[0]

  policy = concat(data.aws_iam_policy_document.bucket.*.json, [""])[0]
}

resource "aws_s3_bucket_public_access_block" "default" {
  count  = local.create_storage_bucket ? 1 : 0
  bucket = concat(aws_s3_bucket.default.*.id, [""])[0]

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  count  = local.create_storage_bucket ? 1 : 0
  bucket = concat(aws_s3_bucket.default.*.id, [""])[0]

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_master_key_arn
      sse_algorithm     = var.sse_algorithm
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "default" {
  count  = local.create_storage_bucket ? 1 : 0
  bucket = concat(aws_s3_bucket.default.*.id, [""])[0]

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "default" {
  count      = local.create_storage_bucket ? 1 : 0
  depends_on = [aws_s3_bucket_ownership_controls.default]

  bucket = concat(aws_s3_bucket.default.*.id, [""])[0]
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "default" {
  count  = local.create_storage_bucket ? 1 : 0
  bucket = concat(aws_s3_bucket.default.*.id, [""])[0]
  versioning_configuration {
    status = var.s3_bucket_versioning ? "Enabled" : "Suspended"
  }
}

module "logs" {
  source     = "git::https://github.com/cloudposse/terraform-aws-s3-log-storage.git?ref=tags/0.26.0"
  enabled    = local.create_storage_bucket && var.s3_bucket_access_logging && var.access_log_bucket_name == null
  namespace  = ""
  stage      = ""
  name       = local.module_prefix
  delimiter  = var.delimiter
  attributes = compact(concat(var.attributes, ["logs"]))

  versioning_enabled = var.s3_bucket_versioning ? true : false

  tags                      = local.tags
  lifecycle_prefix          = var.log_lifecycle_prefix
  standard_transition_days  = var.log_standard_transition_days
  glacier_transition_days   = var.log_glacier_transition_days
  expiration_days           = var.log_expiration_days
  force_destroy             = var.log_force_destroy
  enable_glacier_transition = var.log_enable_glacier_transition
}

resource "aws_s3_bucket_logging" "default" {
  count  = local.create_storage_bucket && var.s3_bucket_access_logging || var.access_log_bucket_name != null ? 1 : 0
  bucket = concat(aws_s3_bucket.default.*.id, [""])[0]

  target_bucket = var.access_log_bucket_name == null ? concat(module.logs.*.bucket_id, [""])[0] : var.access_log_bucket_name
  target_prefix = var.access_log_prefix
}

resource "aws_cloudtrail" "default" {
  count                 = var.create ? 1 : 0
  name                  = join("-", [local.module_prefix, "events"])
  s3_bucket_name        = concat(aws_s3_bucket.default.*.id, [var.s3_bucket_name])[0]
  is_multi_region_trail = var.is_multi_region_trail
  sns_topic_name        = concat(aws_sns_topic.default.*.arn, [var.sns_topic_name])[0]
  tags                  = local.tags
}

data "aws_iam_policy_document" "sns" {
  count = local.create_sns_topic ? 1 : 0
  statement {
    sid = "AWSCloudTrailAclCheck"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = [
      "sns:Publish",
    ]
    resources = [
      "arn:aws:sns:${var.aws_region}:${var.account_id}:${join("-", [local.module_prefix, "*"])}",
    ]
  }

  dynamic "statement" {
    for_each = var.allowed_sns_subscription_accounts == null ? [1] : []
    content {
      sid    = "LocalAccountAccess"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = [var.account_id]
      }
      actions = [
        "sns:Subscribe",
      ]
      resources = [
        "arn:aws:sns:${var.aws_region}:${var.account_id}:${join("-", [local.module_prefix, "*"])}",
      ]
    }
  }

  dynamic "statement" {
    for_each = var.allowed_sns_subscription_accounts != null ? [1] : []
    content {
      sid    = "CrossAccountAccess"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = var.allowed_sns_subscription_accounts
      }
      actions = [
        "sns:Subscribe",
      ]
      resources = [
        "arn:aws:sns:${var.aws_region}:${var.account_id}:${join("-", [local.module_prefix, "*"])}",
      ]
    }
  }
}

resource "aws_sns_topic" "default" {
  count  = local.create_sns_topic ? 1 : 0
  name   = join("-", [local.module_prefix, "events"])
  tags   = local.tags
  policy = concat(data.aws_iam_policy_document.sns.*.json, [""])[0]
}

# ----------------------------------------------------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------------------------------------------------

output "bucket_id" {
  value     = concat(aws_s3_bucket.default.*.id, [""])[0]
  sensitive = false
}

output "bucket_arn" {
  value     = concat(aws_s3_bucket.default.*.arn, [""])[0]
  sensitive = false
}

output "cloudtrail_name" {
  value     = concat(aws_cloudtrail.default.*.name, [""])[0]
  sensitive = false
}

output "sns_topic_arn" {
  value     = concat(aws_sns_topic.default.*.arn, [""])[0]
  sensitive = false
}
