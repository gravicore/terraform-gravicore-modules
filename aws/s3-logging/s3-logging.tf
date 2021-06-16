# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

module "s3_logging" {
  source = "git::https://github.com/gravicore/terraform-gravicore-modules.git//aws/s3?ref=0.32.14"
  providers = {
    aws = aws
  }

  namespace   = var.namespace
  environment = var.environment
  stage       = var.stage
  tags        = local.tags

  name                     = "s3-logging"
  s3_bucket_acl            = "log-delivery-write"
  s3_bucket_versioning     = "true"
  s3_bucket_access_logging = "true"
  s3_logging_bucket        = local.module_prefix
}

# ----------------------------------------------------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------------------------------------------------

output "s3_bucket_id" {
  value       = module.s3_logging.s3_bucket_id
  description = "Id of S3 Logging bucket"
}

output "s3_bucket_arn" {
  value       = module.s3_logging.s3_bucket_arn
  description = "Arn of S3 Logging bucket"
}
