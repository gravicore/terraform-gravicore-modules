variable "acl" {
  type        = string
  description = "Canned ACL to apply to the S3 bucket"
  default     = "log-delivery-write"
}

variable "force_destroy" {
  type        = bool
  description = "A boolean that indicates the bucket can be destroyed even if it contains objects. These objects are not recoverable"
  default     = false
}

variable "lifecycle_prefix" {
  type        = string
  description = "Prefix filter. Used to manage object lifecycle events"
  default     = ""
}

variable "lifecycle_rule_enabled" {
  type        = bool
  description = "A boolean that indicates whether the s3 log bucket lifecycle rule should be enabled."
  default     = false
}

variable "expiration_days" {
  type        = number
  description = "Number of days after which to expunge s3 logs"
  default     = 90
}

variable "noncurrent_version_expiration_days" {
  type        = number
  description = "Specifies when noncurrent s3 log versions expire"
  default     = 90
}

variable "noncurrent_version_transition_days" {
  type        = number
  description = "Specifies when noncurrent s3 log versions transition"
  default     = 30
}

variable "standard_transition_days" {
  type        = number
  description = "Number of days to persist logs in standard storage tier before moving to the infrequent access tier"
  default     = 30
}

variable "lifecycle_tags" {
  type        = map(string)
  description = "Tags filter. Used to manage object lifecycle events"
  default     = {}
}

variable "versioning_enabled" {
  type        = bool
  description = "A state of versioning. Versioning is a means of keeping multiple variants of an object in the same bucket"
  default     = false
}

variable "abort_incomplete_multipart_upload_days" {
  type        = number
  default     = 5
  description = "Maximum time (in days) that you want to allow multipart uploads to remain in progress"
}

variable "sse_algorithm" {
  type        = string
  default     = "AES256"
  description = "The server-side encryption algorithm to use. Valid values are AES256 and aws:kms"
}

variable "kms_master_key_arn" {
  type        = string
  default     = ""
  description = "The AWS KMS master key ARN used for the SSE-KMS encryption. This can only be used when you set the value of sse_algorithm as aws:kms. The default aws/s3 AWS KMS master key is used if this element is absent while the sse_algorithm is aws:kms"
}

variable "block_public_acls" {
  type        = bool
  default     = true
  description = "Set to `false` to disable the blocking of new public access lists on the bucket"
}

variable "block_public_policy" {
  type        = bool
  default     = true
  description = "Set to `false` to disable the blocking of new public policies on the bucket"
}

variable "ignore_public_acls" {
  type        = bool
  default     = true
  description = "Set to `false` to disable the ignoring of public access lists on the bucket"
}

variable "restrict_public_buckets" {
  type        = bool
  default     = true
  description = "Set to `false` to disable the restricting of making the bucket public"
}

resource "aws_s3_bucket" "default" {
  count         = var.create ? 1 : 0
  bucket        = local.module_prefix
  acl           = var.acl
  force_destroy = var.force_destroy
  policy        = <<policy
{
  "Id": "Policy",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${local.module_prefix}/AWSLogs/*",
      "Principal": {
        "AWS": [
          "arn:aws:iam::127311923021:root"
        ]
      }
    }
  ]
}
policy
  versioning {
    enabled = var.versioning_enabled
  }

  lifecycle_rule {
    id                                     = local.module_prefix
    enabled                                = var.lifecycle_rule_enabled
    prefix                                 = var.lifecycle_prefix
    tags                                   = var.lifecycle_tags
    abort_incomplete_multipart_upload_days = var.abort_incomplete_multipart_upload_days

    noncurrent_version_expiration {
      days = var.noncurrent_version_expiration_days
    }


    transition {
      days          = var.standard_transition_days
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = var.expiration_days
    }

  }

  # https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-encryption.html
  # https://www.terraform.io/docs/providers/aws/r/s3_bucket.html#enable-default-server-side-encryption
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = var.sse_algorithm
        kms_master_key_id = var.kms_master_key_arn
      }
    }
  }

  tags = local.tags
}

# Refer to the terraform documentation on s3_bucket_public_access_block at
# https://www.terraform.io/docs/providers/aws/r/s3_bucket_public_access_block.html
# for the nuances of the blocking options
resource "aws_s3_bucket_public_access_block" "default" {
  count  = var.create ? 1 : 0
  bucket = join("", aws_s3_bucket.default.*.id)

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

output "access_log_bucket_domain_name" {
  value       = join("", aws_s3_bucket.default.*.bucket_domain_name)
  description = "FQDN of bucket"
}

output "access_log_bucket_id" {
  value       = join("", aws_s3_bucket.default.*.id)
  description = "Bucket Name (aka ID)"
}

output "access_log_bucket_arn" {
  value       = join("", aws_s3_bucket.default.*.arn)
  description = "Bucket ARN"
}
