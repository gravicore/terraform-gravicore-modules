variable "buckets" {
  type = map(object({
    name = string
    acl = optional(string, "private")
    versioning = optional(bool, true)
    access_logging = optional(bool, false)
    logging_bucket = optional(string, "")
    ssl_requests_only = optional(bool, false)
    sse_algorithm = optional(string, "AES256")
    kms_master_key_arn = optional(string, "")
    cors_rules = optional(list(any), [])
    lifecycle_rules = optional(list(any), [])
    create_service_user = optional(bool, false)
    block_public_acls = optional(bool, true)
    block_public_policy = optional(bool, true)
    ignore_public_acls = optional(bool, true)
    restrict_public_buckets = optional(bool, true)
  }))
  description = "Map of S3 bucket configurations"
  default = {}
}

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

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket" "default" {
  for_each = var.buckets
  bucket   = join(var.delimiter, [local.module_prefix, each.key])
  acl      = each.value.acl

  versioning {
    enabled = each.value.versioning
  }

  dynamic "logging" {
    for_each = each.value.access_logging ? [1] : []
    content {
      target_bucket = each.value.access_logging && each.value.logging_bucket != "" ? each.value.logging_bucket : ""
      target_prefix = join(var.delimiter, [each.value.logging_bucket, "access-logs/"])
    }
  }

  policy = each.value.ssl_requests_only == false ? "" : jsonencode(
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
            "arn:aws:s3:::${join(var.delimiter, [local.module_prefix, each.key])}/*",
            "arn:aws:s3:::${join(var.delimiter, [local.module_prefix, each.key])}"
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
        sse_algorithm     = each.value.sse_algorithm
        kms_master_key_id = each.value.kms_master_key_arn
      }
    }
  }

  dynamic "cors_rule" {
    for_each = each.value.cors_rules
    content {
      allowed_headers = lookup(cors_rule.value, "allowed_headers", null)
      allowed_methods = lookup(cors_rule.value, "allowed_methods", [])
      allowed_origins = lookup(cors_rule.value, "allowed_origins", [])
      expose_headers  = lookup(cors_rule.value, "expose_headers", null)
      max_age_seconds = lookup(cors_rule.value, "max_age_seconds", null)
    }
  }

  dynamic "lifecycle_rule" {
    for_each = each.value.lifecycle_rules
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
  for_each = var.buckets
  bucket   = aws_s3_bucket.default[each.key].id

  block_public_acls       = each.value.block_public_acls
  block_public_policy     = each.value.block_public_policy
  ignore_public_acls      = each.value.ignore_public_acls
  restrict_public_buckets = each.value.restrict_public_buckets
}

resource "aws_iam_user" "default" {
  for_each = { for k, v in var.buckets : k => v if v.create_service_user }
  name     = join(var.delimiter, [local.module_prefix, each.key, "access"])
  tags     = local.tags
}

resource "aws_iam_access_key" "default" {
  for_each = { for k, v in var.buckets : k => v if v.create_service_user }
  user     = aws_iam_user.default[each.key].name
}

resource "aws_iam_user_policy" "default" {
  for_each = { for k, v in var.buckets : k => v if v.create_service_user }
  name     = join(var.delimiter, [local.module_prefix, each.key, "read", "write"])
  user     = aws_iam_user.default[each.key].name

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
        "Resource": ["${aws_s3_bucket.default[each.key].arn}"]
      },
      {
        "Effect": "Allow",
        "Action": [
          "s3:PutObject*",
          "s3:GetObject*",
          "s3:DeleteObject"
        ],
        "Resource": ["${aws_s3_bucket.default[each.key].arn}/*"]
      }
    ]
}
EOF
}

resource "aws_ssm_parameter" "service_access_key_id" {
  for_each    = { for k, v in var.buckets : k => v if v.create_service_user }
  name        = "/${local.stage_prefix}/${var.name}-${each.key}-service-access-key-id"
  description = format("%s %s", var.desc_prefix, "S3 service account Access Key ID for bucket ${each.key}")

  key_id    = var.ssm_key_id
  type      = "SecureString"
  value     = aws_iam_access_key.default[each.key].id
  overwrite = true
  tags      = local.tags
}

resource "aws_ssm_parameter" "service_access_key_secret" {
  for_each    = { for k, v in var.buckets : k => v if v.create_service_user }
  name        = "/${local.stage_prefix}/${var.name}-${each.key}-service-access-key-secret"
  description = format("%s %s", var.desc_prefix, "S3 service account Secret Access Key for bucket ${each.key}")

  key_id    = var.ssm_key_id
  type      = "SecureString"
  value     = aws_iam_access_key.default[each.key].secret
  overwrite = true
  tags      = local.tags
}

# ----------------------------------------------------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------------------------------------------------

output "s3_bucket_ids" {
  value       = { for k, v in aws_s3_bucket.default : k => v.id }
  description = "Map of bucket names to their IDs"
}

output "s3_bucket_arns" {
  value       = { for k, v in aws_s3_bucket.default : k => v.arn }
  description = "Map of bucket names to their ARNs"
}
