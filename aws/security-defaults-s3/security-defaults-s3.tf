# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "s3_bucket_names" {
  type        = list(string)
  default     = []
  description = "s3_bucket_names to apply default security settings to"
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

variable "log_include_cookies" {
  type        = bool
  default     = false
  description = "Include cookies in access logs"
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

variable "attributes" {
  type        = list(string)
  default     = []
  description = "Additional attributes (e.g. `1`)"
}

variable "origin_bucket" {
  type        = string
  default     = ""
  description = "Origin S3 bucket name"
}

variable "origin_path" {
  # http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-values-specify.html#DownloadDistValuesOriginPath
  type        = string
  description = "An optional element that causes CloudFront to request your content from a directory in your Amazon S3 bucket or your custom origin. It must begin with a /. Do not add a / at the end of the path."
  default     = ""
}

variable "origin_force_destroy" {
  type        = bool
  default     = false
  description = "Delete all objects from the bucket  so that the bucket can be destroyed without error (e.g. `true` or `false`)"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

module "logs" {
  source     = "git::https://github.com/cloudposse/terraform-aws-s3-log-storage.git?ref=tags/0.12.0"
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

  tags                     = local.tags
  lifecycle_prefix         = var.log_prefix
  standard_transition_days = var.log_standard_transition_days
  glacier_transition_days  = var.log_glacier_transition_days
  expiration_days          = var.log_expiration_days
  force_destroy            = var.origin_force_destroy
}

resource "null_resource" "update_s3_buckets" {
  count = length(var.s3_bucket_names)

  triggers = {
    s3_bucket_versioning = var.s3_bucket_versioning
    s3_bucket_access_logging = var.s3_bucket_access_logging
    s3_bucket_ssl_requests_only = var.s3_bucket_ssl_requests_only
    script_hash = "${sha256(file("${path.module}/scripts/update-s3-buckets.py"))}"
  }

  provisioner "local-exec" {
    command = "python ./scripts/update-s3-buckets.py ${var.s3_bucket_names[count.index]} ${var.s3_bucket_versioning} ${var.s3_bucket_access_logging} ${var.s3_bucket_ssl_requests_only} ${module.logs.bucket_id}"
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------------------------------------------------