# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "s3_bucket_versioning" {
  description = "S3 bucket versioning enabled?"
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

variable "enable_guardduty_logging" {
  type        = bool
  default     = false
  description = ""
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

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket" "default" {
  count  = var.create ? 1 : 0
  bucket = join("-", [local.module_prefix, "events"])
  region = var.aws_region
  acl    = "private"

  versioning {
    enabled = var.s3_bucket_versioning
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = var.sse_algorithm
        kms_master_key_id = var.kms_master_key_arn
      }
    }
  }
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::${local.module_prefix}-events"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${local.module_prefix}-events/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY
  tags   = local.tags
}

resource "aws_s3_bucket_public_access_block" "default" {
  count  = var.create ? 1 : 0
  bucket = aws_s3_bucket.default[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudtrail" "default" {
  count                 = var.create ? 1 : 0
  name                  = join("-", [local.module_prefix, "events"])
  s3_bucket_name        = aws_s3_bucket.default[0].id
  is_multi_region_trail = true
  tags                  = local.tags
}

# ----------------------------------------------------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------------------------------------------------


output "cloudtrail_name" {
  value       = aws_cloudtrail.default[0].name
  description = ""
}
