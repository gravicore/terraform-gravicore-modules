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
  description = "(Optional) Setting to true creates an s3 bucket for the logs along side the cloudtrail trail"
}

variable "s3_bucket_name" {
  type        = string
  default     = ""
  description = "(Optional) Name of the S3 bucket designated for publishing log files"
}

variable "is_multi_region_trail" {
  type        = bool
  default     = true
  description = "(Optional) Whether the trail is created in the current region or in all regions"
}

variable "enable_log_file_validation" {
  type        = bool
  default     = true
  description = "(Optional) Whether log file integrity validation is enabled"
}

variable "include_global_service_events" {
  type        = bool
  default     = true
  description = "(Optional) Whether the trail is publishing events from global services such as IAM to the log files"
}

variable "enable_logging" {
  type        = bool
  default     = true
  description = "Optional) Enables logging for the trail"
}

variable "cloud_watch_logs_role_arn" {
  type        = string
  description = "(Optional) Role for the CloudWatch Logs endpoint to assume to write to a user’s log group"
  default     = ""
}

variable "cloud_watch_logs_group_arn" {
  type        = string
  description = "(Optional) Log group name using an ARN that represents the log group to which CloudTrail logs will be delivered. Note that CloudTrail requires the Log Stream wildcard"
  default     = ""
}

variable "insight_selector" {
  type = list(object({
    insight_type = string
  }))

  description = "(Optional) Configuration block for identifying unusual operational activity"
  default     = []
}

variable "event_selector" {
  type = list(object({
    include_management_events        = bool
    read_write_type                  = string
    exclude_management_event_sources = optional(set(string))

    data_resource = list(object({
      type   = string
      values = list(string)
    }))
  }))

  description = "(Optional) Specifies an event selector for enabling data event logging. Fields documented below. Please note the CloudTrail limits(https://docs.aws.amazon.com/awscloudtrail/latest/userguide/WhatIsCloudTrail-Limits.html) when configuring these. Conflicts with advanced_event_selector"
  default     = []
}

variable "advanced_event_selector" {
  type = list(object({
    name = optional(string)
    field_selector = list(object({
      field           = string
      ends_with       = optional(list(string))
      not_ends_with   = optional(list(string))
      equals          = optional(list(string))
      not_equals      = optional(list(string))
      starts_with     = optional(list(string))
      not_starts_with = optional(list(string))
    }))
  }))
  description = "(Optional) Specifies an advanced event selector for enabling data event logging. Fields documented below. Conflicts with event_selector"
  default     = []
}

variable "is_organization_trail" {
  type        = bool
  default     = false
  description = "(Optional) Whether the trail is an AWS Organizations trail. Organization trails log events for the master account and all member accounts. Can only be created in the organization master account"
}

variable "s3_key_prefix" {
  type        = string
  description = "(Optional) S3 key prefix that follows the name of the bucket you have designated for log file delivery"
  default     = null
}

variable "kms_cloudtrail_key_arn" {
  type        = string
  default     = null
  description = "(Optional) KMS key ARN to use to encrypt the logs delivered by CloudTrail"
}

variable "allowed_sns_subscription_accounts" {
  type        = list(string)
  default     = null
  description = "description"
}

variable "enable_sns_encryption" {
  type        = bool
  default     = false
  description = "Enable encryption for SNS topic"
}

variable "kms_sns_key_arn" {
  type        = string
  default     = null
  description = "KMS key ARN for SNS encryption"
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
  source     = "git::https://github.com/cloudposse/terraform-aws-s3-log-storage.git?ref=tags/1.4.3"
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
  count = var.create ? 1 : 0
  name  = join("-", [local.module_prefix, "events"])
  tags  = local.tags

  s3_bucket_name                = concat(aws_s3_bucket.default.*.id, [var.s3_bucket_name])[0]
  s3_key_prefix                 = var.s3_key_prefix
  is_multi_region_trail         = var.is_multi_region_trail
  is_organization_trail         = var.is_organization_trail
  include_global_service_events = var.include_global_service_events
  enable_logging                = var.enable_logging
  enable_log_file_validation    = var.enable_log_file_validation
  sns_topic_name                = concat(aws_sns_topic.default.*.arn, [var.sns_topic_name])[0]
  cloud_watch_logs_role_arn     = var.cloud_watch_logs_role_arn
  cloud_watch_logs_group_arn    = var.cloud_watch_logs_group_arn
  kms_key_id                    = var.kms_cloudtrail_key_arn

  dynamic "insight_selector" {
    for_each = var.insight_selector
    content {
      insight_type = insight_selector.value.insight_type
    }
  }

  dynamic "event_selector" {
    for_each = var.event_selector
    content {
      include_management_events        = lookup(event_selector.value, "include_management_events", null)
      read_write_type                  = lookup(event_selector.value, "read_write_type", null)
      exclude_management_event_sources = event_selector.value.exclude_management_event_sources

      dynamic "data_resource" {
        for_each = lookup(event_selector.value, "data_resource", [])
        content {
          type   = data_resource.value.type
          values = data_resource.value.values
        }
      }
    }
  }

  dynamic "advanced_event_selector" {
    for_each = var.advanced_event_selector
    content {
      name = lookup(advanced_event_selector.value, "name", null)

      dynamic "field_selector" {
        for_each = advanced_event_selector.value.field_selector
        content {
          field           = field_selector.value.field
          equals          = lookup(field_selector.value, "equals", null)
          not_equals      = lookup(field_selector.value, "not_equals", null)
          starts_with     = lookup(field_selector.value, "starts_with", null)
          not_starts_with = lookup(field_selector.value, "not_starts_with", null)
          ends_with       = lookup(field_selector.value, "ends_with", null)
          not_ends_with   = lookup(field_selector.value, "not_ends_with", null)
        }
      }
    }
  }
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
  count             = local.create_sns_topic ? 1 : 0
  name              = join("-", [local.module_prefix, "events"])
  kms_master_key_id = var.enable_sns_encryption ? var.kms_sns_key_arn : null
  tags              = local.tags
  policy            = concat(data.aws_iam_policy_document.sns.*.json, [""])[0]
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
