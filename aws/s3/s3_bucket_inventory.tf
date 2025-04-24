variable "bucket_inventory" {
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
    for_each = lookup(each.value, "filter", null) != null ? [lookup(each.value, "filter", "")] : []
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
        for_each = lookup(each.value, "destination_bucket_sse_kms", null) != null ? [lookup(each.value, "destination_bucket_sse_kms", "")] : []
        content {
          sse_kms {
            key_id = encryption.value
          }
        }
      }
      dynamic "encryption" {
        for_each = lookup(each.value, "destination_bucket_sse_s3", null) ? [lookup(each.value, "destination_bucket_sse_s3", "")] : []
        content {
          sse_s3 {}
        }
      }
    }
  }
  optional_fields = lookup(each.value, "optional_fields", null)
}

# ----------------------------------------------------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------------------------------------------------

output "s3_bucket_inventory_policy" {
  value       = var.bucket_inventory == {} ? "" : <<EOF

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
