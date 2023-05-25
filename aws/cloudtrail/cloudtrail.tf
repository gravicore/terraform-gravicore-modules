# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "attributes" {
  type        = list(string)
  default     = []
  description = "Additional attributes (e.g. `1`)"
}

variable "origin_force_destroy" {
  type        = bool
  default     = false
  description = "Delete all objects from the bucket  so that the bucket can be destroyed without error (e.g. `true` or `false`)"
}

variable "log_prefix" {
  type        = string
  default     = "cloudfront"
  description = "Path of logs in S3 bucket"
}

variable "log_standard_transition_days" {
  description = "Number of days to persist in the standard storage tier before moving to the glacier tier"
  default     = 30
}

variable "log_glacier_transition_days" {
  description = "Number of days after which to move the data to the glacier storage tier"
  default     = 60
}

variable "log_expiration_days" {
  description = "Number of days after which to expunge the objects"
  default     = 90
}

variable "s3_bucket_versioning" {
  type        = bool
  description = "S3 bucket versioning enabled?"
  default     = false
}

variable "s3_bucket_access_logging" {
  type        = bool
  description = "Access logging of S3 buckets"
  default     = false
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

variable "enable_glacier_transition" {
  type        = bool
  default     = false
  description = "Enables the transition to AWS Glacier which can cause unnecessary costs for huge amount of small files"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket" "default" {
  count  = var.create ? 1 : 0
  bucket = join("-", [local.module_prefix, "events"])
  acl    = "private"

  dynamic "logging" {
    for_each = var.s3_bucket_access_logging ? [1] : []
    content {
      target_bucket = module.logs.bucket_id
      target_prefix = "access-logs/"
    }
  }

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
        },
        {
          "Principal": {
            "AWS": "*"
          },
          "Action": [
            "s3:*"
          ],
          "Resource": [
            "arn:aws:s3:::${local.module_prefix}-events/*",
            "arn:aws:s3:::${local.module_prefix}-events"
          ],
          "Effect": "Deny",
          "Condition": {
            "Bool": {
              "aws:SecureTransport": "false"
            }
          }
        }
    ]
}
POLICY
  tags   = local.tags
}

module "logs" {
  source     = "git::https://github.com/cloudposse/terraform-aws-s3-log-storage.git?ref=tags/0.26.0"
  namespace  = ""
  stage      = ""
  name       = local.module_prefix
  delimiter  = var.delimiter
  attributes = compact(concat(var.attributes, ["logs"]))

  versioning_enabled     = var.s3_bucket_versioning ? true : false
  access_log_bucket_name = var.s3_bucket_access_logging ? join(var.delimiter, [local.module_prefix, "logs"]) : ""

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
            "arn:aws:s3:::${join(var.delimiter, [local.module_prefix, "logs"])}/*",
            "arn:aws:s3:::${join(var.delimiter, [local.module_prefix, "logs"])}"
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

  tags                      = local.tags
  lifecycle_prefix          = var.log_prefix
  standard_transition_days  = var.log_standard_transition_days
  glacier_transition_days   = var.log_glacier_transition_days
  expiration_days           = var.log_expiration_days
  force_destroy             = var.origin_force_destroy
  enable_glacier_transition = var.enable_glacier_transition
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

output "cloudtrail_bucket_id" {
  value       = aws_s3_bucket.default[0].id
  description = ""
}

output "cloudtrail_bucket_arn" {
  value       = aws_s3_bucket.default[0].arn
  description = ""
}

output "cloudtrail_name" {
  value       = aws_cloudtrail.default[0].name
  description = ""
}
