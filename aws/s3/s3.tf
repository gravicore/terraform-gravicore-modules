variable "s3_bucket_versioning" {
  type        = bool
  description = "S3 bucket versioning enabled?"
  default     = true
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

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket" "default" {
  count  = var.create ? 1 : 0
  bucket = local.module_prefix
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
  name  = "${local.module_prefix}-access"
  tags  = local.tags
}

resource "aws_iam_access_key" "default" {
  count = var.create && var.create_s3_service_user ? 1 : 0
  user  = aws_iam_user.default[0].name
}

resource "aws_iam_user_policy" "default" {
  count = var.create && var.create_s3_service_user ? 1 : 0
  name  = "${local.module_prefix}-read-write"
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
