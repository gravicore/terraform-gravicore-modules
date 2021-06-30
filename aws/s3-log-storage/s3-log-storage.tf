variable "s3_log_storage_bucket_name" {
  type        = string
  description = "S3 log storage bucket name"
  default     = "s3-log-storage"
}

variable "s3_bucket_versioning" {
  type        = bool
  description = "S3 bucket versioning enabled?"
  default     = true
}

variable "s3_bucket_access_logging" {
  type        = bool
  description = "Access logging of S3 buckets"
  default     = true
}

variable "s3_bucket_ssl_requests_only" {
  type        = bool
  description = "S3 bucket ssl requests only?"
  default     = true
}

variable "s3_bucket_acl" {
  type        = string
  description = "S3 bucket acl"
  default     = "log-delivery-write"
}

variable "s3_lifecycle_expiration_enabled" {
  type        = bool
  description = "S3 lifecycle expiration enabled?"
  default     = false
}

variable "s3_lifecycle_expiration_days" {
  type        = number
  description = "S3 lifecycle expiration days"
  default     = 45
}

variable "s3_lifecycle_rules" {
  type = list(any)
  default = [
    {
      id      = "Rule for S3 Log Storage"
      enabled = true
      prefix  = "s3_log_storage/"

      noncurrent_version_transition = {
        days          = 45
        storage_class = "STANDARD_IA"

      }

      transition = {
        days          = 45
        storage_class = "STANDARD_IA"
      }

    }
  ]
  description = "The configuration of the object for lifecycle management"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

module "s3_log_storage" {
  source = "git::https://github.com/gravicore/terraform-gravicore-modules.git//aws/s3?ref=0.32.14"
  providers = {
    aws = aws
  }

  namespace   = var.namespace
  environment = var.environment
  stage       = var.stage
  tags        = local.tags

  name                        = var.s3_log_storage_bucket_name
  s3_bucket_acl               = var.s3_bucket_acl
  s3_bucket_versioning        = var.s3_bucket_versioning
  s3_bucket_access_logging    = var.s3_bucket_access_logging
  s3_bucket_ssl_requests_only = var.s3_bucket_ssl_requests_only

  lifecycle_rules   = var.s3_lifecycle_rules
  s3_logging_bucket = local.module_prefix
}

# ----------------------------------------------------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------------------------------------------------

output "s3_bucket_id" {
  value       = module.s3_log_storage.s3_bucket_id
  description = "Id of S3 Logging bucket"
}

output "s3_bucket_arn" {
  value       = module.s3_log_storage.s3_bucket_arn
  description = "Arn of S3 Logging bucket"
}
