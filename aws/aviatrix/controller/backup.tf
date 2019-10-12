# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "s3_backup_versioning_enabled" {
  type        = bool
  default     = false
  description = "A state of versioning. Versioning is a means of keeping multiple variants of an object in the same bucket"
}

variable "s3_backup_kms_key_arn" {
  type        = string
  default     = ""
  description = "The AWS KMS key ARN used for the SSE-KMS encryption. This can only be used when you set the value of sse_algorithm as aws:kms. The default aws/s3 AWS KMS master key is used if this element is absent while the sse_algorithm is aws:kms"
}

variable "s3_backup_allowed_bucket_actions" {
  type        = list(string)
  default     = ["s3:PutObject", "s3:PutObjectAcl", "s3:GetObject", "s3:DeleteObject", "s3:ListBucket", "s3:ListBucketMultipartUploads", "s3:GetBucketLocation", "s3:AbortMultipartUpload"]
  description = ""
}

locals {
  s3_backup_delete = var.s3_backup_versioning_enabled ? "" : "s3:DeleteObject"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

module "s3_backup" {
  source    = "git::https://github.com/cloudposse/terraform-aws-s3-bucket.git?ref=0.5.0"
  enabled   = var.create
  namespace = ""
  stage     = ""
  name      = "${local.module_prefix}-backup"

  sse_algorithm      = var.s3_backup_kms_key_arn == "" ? "AES256" : "aws:kms"
  kms_master_key_arn = var.s3_backup_kms_key_arn

  versioning_enabled     = var.s3_backup_versioning_enabled
  allowed_bucket_actions = var.s3_backup_allowed_bucket_actions
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

# SSM Parameters

module "parameters_backup" {
  source = "git::https://github.com/gravicore/terraform-gravicore-modules.git//aws/parameters?ref=0.20.0"
  providers   = { aws = "aws" }
  create      = var.create
  namespace   = var.namespace
  environment = var.environment
  stage       = var.stage
  tags        = local.tags

  write_parameters = {
    "/${local.stage_prefix}/${var.name}-backup-s3-bucket-id" = { value = module.s3_backup.bucket_id,
    description = "ID of the Aviatrix Backup S3 bucket" }
    "/${local.stage_prefix}/${var.name}-backup-s3-bucket-arn" = { value = module.s3_backup.bucket_arn,
    description = "ARN of the Aviatrix Backup S3 bucket" }
    "/${local.stage_prefix}/${var.name}-backup-s3-bucket-domain-name" = { value = module.s3_backup.bucket_domain_name,
    description = "FQDN of the Aviatrix Backup S3 bucket" }
  }
}

# Outputs

output "backup_s3_bucket_id" {
  value       = module.s3_backup.bucket_id
  description = "ID of the Aviatrix Backup S3 bucket"
}

output "backup_s3_bucket_arn" {
  value       = module.s3_backup.bucket_arn
  description = "ARN of the Aviatrix Backup S3 bucket"
}

output "backup_s3_bucket_domain_name" {
  value       = module.s3_backup.bucket_domain_name
  description = "FQDN of the Aviatrix Backup S3 bucket"
}
