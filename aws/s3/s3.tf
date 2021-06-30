variable "s3_bucket_versioning" {
  type        = bool
  description = "S3 bucket versioning enabled?"
  default     = true
}

variable "s3_bucket_access_logging" {
  type        = bool
  description = "Access logging of S3 buckets"
  default     = false
}

variable "s3_logging_bucket" {
  type        = string
  description = "S3 logging bucket name for logs"
  default     = ""
}

variable "s3_bucket_ssl_requests_only" {
  type        = bool
  description = "S3 bucket ssl requests only?"
  default     = false
}

variable "s3_bucket_acl" {
  type        = string
  description = "S3 bucket acl"
  default     = "private"
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

variable "cors_rules" {
  type        = list(any)
  default     = []
  description = "The configuration of the object for CORS management"
}

variable "lifecycle_rules" {
  type        = list(any)
  default     = []
  description = "The configuration of the object for lifecycle management"
}

variable "create_s3_service_user" {
  type        = bool
  default     = false
  description = "Creates a read only service user for congito"
}

variable "block_public_acls" {
  type        = bool
  description = "Whether Amazon S3 should block public ACLs for this bucket"
  default     = true
}

variable "block_public_policy" {
  type        = bool
  description = "Whether Amazon S3 should block public bucket policies for this bucket"
  default     = true
}

variable "ignore_public_acls" {
  type        = bool
  description = "Whether Amazon S3 should ignore public ACLs for this bucket"
  default     = true
}

variable "restrict_public_buckets" {
  type        = bool
  description = "Whether Amazon S3 should restrict public bucket policies for this bucket"
  default     = true
}

variable "ssm_key_id" {
  type        = string
  default     = ""
  description = "The KMS key id or arn for encrypting a SecureString"
}

variable bucket_inventory {
  type        = map(any)
  default     = {}
  description = <<EOF
bucket_inventory = {
  <id> = {                        # string,       (Required) Unique identifier of the inventory configuration for the bucket 
    enabled                       = bool,         (Optional, Default: true) Specifies whether the inventory is enabled or disabled
    frequency                     = string,       (Required, Default: Daily) Specifies how frequently inventory results are produced. Valid values: Daily, Weekly.
    filter                        = string,       (Optional) The prefix that an object must have to be included in the inventory results
    included_object_versions      = string,       (Required, Default: All) Object versions to include in the inventory list. Valid values: All, Current
    optional_fields               = list(string), (Optional) List of optional fields that are included in the inventory results. Valid values: Size, LastModifiedDate, StorageClass, ETag, IsMultipartUploaded, ReplicationStatus, EncryptionStatus, ObjectLockRetainUntilDate, ObjectLockMode, ObjectLockLegalHoldStatus, IntelligentTieringAccessTier
    destination_bucket_format     = string,       (Required) Specifies the output format of the inventory results. Can be CSV, ORC or Parquet
    destination_bucket_bucket_arn = string,       (Required) The Amazon S3 bucket ARN of the destination
    destination_bucket_prefix     = string,       (Optional) The prefix that is prepended to all inventory results
    destination_account_id        = string        (Optional) The ID of the account that owns the destination bucket. Recommended to be set to prevent problems if the destination bucket ownership changes
    destination_bucket_sse_s3     = bool,         (Optional) Specifies to use server-side encryption with Amazon S3-managed keys (SSE-S3) to encrypt the inventory file
    destination_bucket_sse_kms    = string,       (Optional) The ARN of the KMS customer master key (CMK) used to encrypt the inventory file.
  }
}

Each destination bucket will need a policy added as follows

{
  "Version": "2008-10-17",
  "Id": "SegmentWritePolicy",
  "Statement": [
    {
      "Sid": "InventoryPolicy",
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "<destination_bucket_bucket_arn>/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control",
          "aws:SourceAccount": "<source_bucket_account_id>"
        },
        "ArnLike": {
          "aws:SourceArn": "<source_bucket_arn>"
        }
      }
    }
  ]
}
EOF
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket" "default" {
  count  = var.create ? 1 : 0
  bucket = local.module_prefix
  acl    = var.s3_bucket_acl

  versioning {
    enabled = var.s3_bucket_versioning
  }

  dynamic "logging" {
    for_each = var.s3_bucket_access_logging ? [1] : []
    content {
      target_bucket = var.s3_bucket_access_logging && var.s3_logging_bucket != "" ? var.s3_logging_bucket : ""
      target_prefix = join(var.delimiter, [var.s3_logging_bucket, "access-logs/"])
    }
  }

  policy = var.s3_bucket_ssl_requests_only == false ? "" : jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "AllowSSLRequestsOnly",
          "Principal" : {
            "AWS" : "*"
          },
          "Action" : [
            "s3:*"
          ],
          "Resource" : [
            "arn:aws:s3:::${local.module_prefix}/*",
            "arn:aws:s3:::${local.module_prefix}"
          ],
          "Effect" : "Deny",
          "Condition" : {
            "Bool" : {
              "aws:SecureTransport" : "false"
            }
          }
        }
      ]
  })

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = var.sse_algorithm
        kms_master_key_id = var.kms_master_key_arn
      }
    }
  }

  dynamic "cors_rule" {
    for_each = var.cors_rules
    content {
      allowed_headers = lookup(cors_rule.value, "allowed_headers", null)
      allowed_methods = lookup(cors_rule.value, "allowed_methods", [])
      allowed_origins = lookup(cors_rule.value, "allowed_origins", [])
      expose_headers  = lookup(cors_rule.value, "expose_headers", null)
      max_age_seconds = lookup(cors_rule.value, "max_age_seconds", null)
    }
  }

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules
    content {
      id                                     = lifecycle_rule.value.id
      prefix                                 = lifecycle_rule.value.prefix
      enabled                                = lifecycle_rule.value.enabled
      abort_incomplete_multipart_upload_days = lookup(lifecycle_rule.value, "abort_incomplete_multipart_upload_days", null)

      dynamic "expiration" {
        for_each = lookup(lifecycle_rule.value, "expiration", null) != null ? [1] : []
        content {
          date                         = lookup(lifecycle_rule.value.expiration, "date", null)
          days                         = lookup(lifecycle_rule.value.expiration, "days", null)
          expired_object_delete_marker = lookup(lifecycle_rule.value.expiration, "expired_object_delete_marker", null)
        }
      }

      dynamic "transition" {
        for_each = lookup(lifecycle_rule.value, "transition", null) != null ? [1] : []
        content {
          date          = lookup(lifecycle_rule.value.transition, "date", null)
          days          = lookup(lifecycle_rule.value.transition, "days", null)
          storage_class = lookup(lifecycle_rule.value.transition, "storage_class", null)
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = lookup(lifecycle_rule.value, "noncurrent_version_expiration", null) != null ? [1] : []
        content {
          days = lookup(lifecycle_rule.value.noncurrent_version_expiration, "days", null)
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = lookup(lifecycle_rule.value, "noncurrent_version_transition", null) != null ? [1] : []
        content {
          days          = lookup(lifecycle_rule.value.noncurrent_version_transition, "days", null)
          storage_class = lookup(lifecycle_rule.value.noncurrent_version_transition, "storage_class", null)
        }
      }
    }
  }

  tags = local.tags
}

resource "aws_s3_bucket_inventory" "default" {
  for_each = var.bucket_inventory
  bucket   = aws_s3_bucket.default[0].id
  name     = each.key
  enabled  = lookup(each.value, "enabled", true)

  included_object_versions = lookup(each.value, "included_object_versions", "All")

  schedule {
    frequency = lookup(each.value, "schedule_frequency", "Daily")
  }

  dynamic "filter" {
    for_each = lookup(each.value, "filter", null) != null ? list(lookup(each.value, "filter", "")) : []
    content {
      prefix = filter.value
    }
  }

  destination {
    bucket {
      format     = each.value.destination_bucket_format
      bucket_arn = each.value.destination_bucket_bucket_arn
      prefix     = lookup(each.value, "destination_bucket_prefix", null)
      account_id = lookup(each.value, "destination_account_id", null)
      dynamic "encryption" {
        for_each = lookup(each.value, "destination_bucket_sse_kms", null) != null ? list(lookup(each.value, "destination_bucket_sse_kms", "")) : []
        content {
          sse_kms {
            key_id = encryption.value
          }
        }
      }
      dynamic "encryption" {
        for_each = lookup(each.value, "destination_bucket_sse_s3", null) ? list(lookup(each.value, "destination_bucket_sse_s3", "")) : []
        content {
          sse_s3 {}
        }
      }
    }
  }
  optional_fields = lookup(each.value, "optional_fields", null)
}

resource "aws_s3_bucket_public_access_block" "default" {
  count  = var.create ? 1 : 0
  bucket = aws_s3_bucket.default[0].id

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

resource "aws_iam_user" "default" {
  count = var.create && var.create_s3_service_user ? 1 : 0
  name  = join(var.delimiter, [local.module_prefix, "access"])
  tags  = local.tags
}

resource "aws_iam_access_key" "default" {
  count = var.create && var.create_s3_service_user ? 1 : 0
  user  = aws_iam_user.default[0].name
}

resource "aws_iam_user_policy" "default" {
  count = var.create && var.create_s3_service_user ? 1 : 0
  name  = join(var.delimiter, [local.module_prefix, "read", "write"])
  user  = aws_iam_user.default[0].name

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "s3:GetBucketLocation",
          "s3:ListAllMyBuckets"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "s3:ListBucket*"
        ],
        "Resource": ["${aws_s3_bucket.default[0].arn}"]
      },
      {
        "Effect": "Allow",
        "Action": [
          "s3:PutObject*",
          "s3:GetObject*",
          "s3:DeleteObject"
        ],
        "Resource": ["${aws_s3_bucket.default[0].arn}/*"]
      }
    ]
}
EOF
}

resource "aws_ssm_parameter" "service_access_key_id" {
  count       = var.create && var.create_s3_service_user ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-service-access-key-id"
  description = format("%s %s", var.desc_prefix, "S3 service account Access Key ID")

  key_id    = var.ssm_key_id
  type      = "SecureString"
  value     = aws_iam_access_key.default[0].id
  overwrite = true
  tags      = local.tags
}

resource "aws_ssm_parameter" "service_access_key_secret" {
  count       = var.create && var.create_s3_service_user ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-service-access-key-secret"
  description = format("%s %s", var.desc_prefix, "S3 service account Secret Access Key")

  key_id    = var.ssm_key_id
  type      = "SecureString"
  value     = aws_iam_access_key.default[0].secret
  overwrite = true
  tags      = local.tags
}

# ----------------------------------------------------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------------------------------------------------

output "s3_bucket_id" {
  value       = aws_s3_bucket.default[0].id
  description = "Id of S3 bucket"
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.default[0].arn
  description = "Arn of S3 bucket"
}

output "s3_bucket_inventory_policy" {
  value = var.bucket_inventory == {} ? "" : <<EOF

Each destination bucket will need a policy added as follows

{
  "Version": "2008-10-17",
  "Id": "SegmentWritePolicy",
  "Statement": [
    {
      "Sid": "InventoryPolicy",
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "<destination_bucket_bucket_arn>/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control",
          "aws:SourceAccount": "${var.account_id}"
        },
        "ArnLike": {
          "aws:SourceArn": "${aws_s3_bucket.default[0].arn}"
        }
      }
    }
  ]
}
EOF
  description = "Bucket policy required by destination bucket to receive logs"
}