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
  description = "Enable GaurdDuty Logging?"
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

variable "cloudtrail_name" {
  type        = string
  default     = null
  description = ""
}

variable "waf_arns" {
  type        = list(any)
  default     = null
  description = ""
}

variable "cloudtrail_log_bucket_id" {
  type        = string
  default     = null
  description = ""
}

variable "cloudtrail_log_bucket_arn" {
  type        = string
  default     = null
  description = ""
}

variable "kinesis_kms_key" {
  type        = string
  default     = null
  description = ""
}

variable "enable_cspm" {
  type        = bool
  default     = false
  description = "Enable Cloud Security Posture Management?"
}

variable "enable_glacier_transition" {
  type        = bool
  default     = false
  description = "Enables the transition to AWS Glacier which can cause unnecessary costs for huge amount of small files"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

module "logs" {
  source     = "git::https://github.com/cloudposse/terraform-aws-s3-log-storage.git?ref=tags/0.12.0"
  enabled    = var.create && var.cloudtrail_name == null ? true : false
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

resource "aws_s3_bucket" "default" {
  count  = var.create && var.cloudtrail_name == null ? 1 : 0
  bucket = "${local.module_prefix}-cloudtrail-events"
  tags   = local.tags

  acl = "private"

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
            "Resource": "arn:aws:s3:::${local.module_prefix}-cloudtrail-events"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${local.module_prefix}-cloudtrail-events/*",
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
            "arn:aws:s3:::${local.module_prefix}-cloudtrail-events/*",
            "arn:aws:s3:::${local.module_prefix}-cloudtrail-events"
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
}

resource "aws_s3_bucket_public_access_block" "default" {
  count  = var.create && var.cloudtrail_name == null ? 1 : 0
  bucket = concat(aws_s3_bucket.default.*.id, [""])[0]

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudtrail" "default" {
  count                 = var.create && var.cloudtrail_name == null ? 1 : 0
  name                  = join(var.delimiter, [local.module_prefix])
  s3_bucket_name        = concat(aws_s3_bucket.default.*.id, [""])[0]
  is_multi_region_trail = true
}

resource "aws_cloudformation_stack" "cloudtrail" {
  count        = var.create ? 1 : 0
  name         = join(var.delimiter, [local.module_prefix])
  capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM"]

  parameters = {
    cloudtrailTrail = var.cloudtrail_name == null ? concat(aws_cloudtrail.default.*.name, [""])[0] : var.cloudtrail_name
  }


  template_url = "https://s3.amazonaws.com/arcticwolf-public/install/aws-templates/latest/primary_region_template.json"
}

# GuardDuty

data "aws_guardduty_detector" "default" {
  count = var.create && var.enable_guardduty_logging && var.guardduty_detector_id == null ? 1 : 0
}

resource "aws_cloudformation_stack" "guardduty" {
  count        = var.create && var.enable_guardduty_logging ? 1 : 0
  name         = join(var.delimiter, [local.module_prefix, "guardduty"])
  capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM"]

  parameters = {
    GuardDutyDetectorID = coalesce(var.guardduty_detector_id, concat(data.aws_guardduty_detector.default.*.id, [""])[0])
  }


  template_url = "https://s3.amazonaws.com/arcticwolf-public/install/aws-templates/latest/awn_guardduty_template.json"

  depends_on = [
    aws_cloudformation_stack.cloudtrail,
  ]
}

# VPC Flow Logs

resource "aws_cloudformation_stack" "vpc_flow_log" {
  count        = var.create && var.vpc_id != null ? 1 : 0
  name         = join(var.delimiter, [local.module_prefix, "vpc-flow-log"])
  capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM"]

  parameters = {
    vpcId = var.vpc_id
  }


  template_url = "https://s3.amazonaws.com/arcticwolf-public/install/aws-templates/latest/vpcflowlogs_template.json"

  depends_on = [
    aws_cloudformation_stack.cloudtrail,
  ]
}

resource "aws_cloudformation_stack" "vpc_flow_log_group" {
  count        = var.create && var.vpc_flow_log_group_name != null ? 1 : 0
  name         = join(var.delimiter, [local.module_prefix, "vpc-flow-log-group"])
  capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM"]

  parameters = {
    filterPattern = var.flow_log_filter_pattern
    logGroupName  = var.vpc_flow_log_group_name
  }


  template_url = "https://s3.amazonaws.com/arcticwolf-public/install/aws-templates/latest/cloudwatch_logs_template.json"

  depends_on = [
    aws_cloudformation_stack.cloudtrail,
  ]
}

# WAF Logging

locals {
  waf_log_prefix = "AWN/WAF/${var.account_id}/"
}

resource "aws_kms_key" "default" {
  count                    = var.create && var.waf_arns != null && var.kinesis_kms_key == null ? 1 : 0
  deletion_window_in_days  = 10
  enable_key_rotation      = true
  tags                     = local.tags
  description              = join(" ", [var.desc_prefix, "KMS Key for encrypting logs collected for monitoring by Arctic Wolf Networks"])
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  policy                   = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": [
        "kms:GenerateDataKey",
        "kms:GenerateDataKeyWithoutPlaintext"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "kms:EncryptionContext:aws:cloudtrail:arn": "arn:aws:cloudtrail:*:${var.account_id}:trail/*"
        }
      }
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "kms:DescribeKey",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::213881032452:root"
      },
      "Action": "kms:Decrypt",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "kms:CallerAccount": "${var.account_id}"
        },
        "StringLike": {
          "kms:EncryptionContext:aws:cloudtrail:arn": "arn:aws:cloudtrail:*:${var.account_id}:trail/*"
        }
      }
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::213881032452:root"
      },
      "Action": "kms:Decrypt",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "kms:CallerAccount": "${var.account_id}"
        },
        "StringLike": {
          "kms:EncryptionContext:aws:s3:arn": "${var.cloudtrail_name != null ? var.cloudtrail_log_bucket_arn : concat(aws_s3_bucket.default.*.arn, [""])[0]}/*"
        }
      }
    }
  ]
}
EOF
}

resource "aws_kms_alias" "default" {
  count         = var.create && var.waf_arns != null && var.kinesis_kms_key == null ? 1 : 0
  name          = "alias/${replace(local.stage_prefix, var.delimiter, "/")}/AWN"
  target_key_id = concat(aws_kms_key.default.*.id, [""])[0]
}

resource "aws_iam_role" "kinesis" {
  count       = var.create && var.waf_arns != null ? 1 : 0
  name        = join(var.delimiter, [local.module_prefix, "kinesis"])
  tags        = local.tags
  description = "${var.desc_prefix} Role for Kinesis fire hose"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "kinesis" {
  count = var.create && var.waf_arns != null ? 1 : 0
  name  = join(var.delimiter, [local.module_prefix, "kinesis"])
  role  = concat(aws_iam_role.kinesis.*.id, [""])[0]

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "glue:GetTable",
        "glue:GetTableVersion",
        "glue:GetTableVersions"
      ],
      "Resource": [
        "arn:aws:glue:${var.aws_region}:${var.account_id}:catalog",
        "arn:aws:glue:${var.aws_region}:${var.account_id}:database/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%",
        "arn:aws:glue:${var.aws_region}:${var.account_id}:table/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:AbortMultipartUpload",
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:ListBucketMultipartUploads",
        "s3:PutObject"
      ],
      "Resource": [
        "${var.cloudtrail_name != null ? var.cloudtrail_log_bucket_arn : concat(aws_s3_bucket.default.*.arn, [""])[0]}",
        "${var.cloudtrail_name != null ? var.cloudtrail_log_bucket_arn : concat(aws_s3_bucket.default.*.arn, [""])[0]}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction",
        "lambda:GetFunctionConfiguration"
      ],
      "Resource": "arn:aws:lambda:${var.aws_region}:${var.account_id}:function:%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:GenerateDataKey",
        "kms:Decrypt"
      ],
      "Resource": "${var.kinesis_kms_key == null ? concat(aws_kms_key.default.*.arn, [""])[0] : var.kinesis_kms_key}",
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "s3.${var.aws_region}.amazonaws.com"
        },
        "StringLike": {
          "kms:EncryptionContext:aws:s3:arn": "${var.cloudtrail_name != null ? var.cloudtrail_log_bucket_arn : concat(aws_s3_bucket.default.*.arn, [""])[0]}/*"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": "logs:PutLogEvents",
      "Resource": "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:/aws/kinesisfirehose/aws-waf-logs-${var.aws_region}-${local.stage_prefix}:log-stream:*"
    },        
    {
      "Effect": "Allow",
      "Action": [
        "kinesis:DescribeStream",
        "kinesis:GetShardIterator",
        "kinesis:GetRecords",
        "kinesis:ListShards"
      ],
      "Resource": "arn:aws:kinesis:${var.aws_region}:${var.account_id}:stream/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "arn:aws:kms:${var.aws_region}:${var.account_id}:key/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%",
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "kinesis.${var.aws_region}.amazonaws.com"
        },
        "StringLike": {
          "kms:EncryptionContext:aws:kinesis:arn": "arn:aws:kinesis:${var.aws_region}:${var.account_id}:stream/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%"
        }
      }
    }
  ]
}
EOF
}

resource "aws_kinesis_firehose_delivery_stream" "waf_logs" {
  count = var.create && var.waf_arns != null ? 1 : 0
  name  = join(var.delimiter, ["aws-waf-logs", var.aws_region, local.stage_prefix])
  tags  = local.tags

  destination = "extended_s3"

  server_side_encryption {
    enabled = true
  }

  extended_s3_configuration {
    role_arn           = concat(aws_iam_role.kinesis.*.arn, [""])[0]
    bucket_arn         = var.cloudtrail_name != null ? var.cloudtrail_log_bucket_arn : concat(aws_s3_bucket.default.*.arn, [""])[0]
    s3_backup_mode     = "Disabled"
    prefix             = local.waf_log_prefix
    kms_key_arn        = var.kinesis_kms_key == null ? concat(aws_kms_key.default.*.arn, [""])[0] : var.kinesis_kms_key
    compression_format = "GZIP"
    buffer_interval    = 300
    buffer_size        = 5

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = "/aws/kinesisfirehose/aws-waf-logs-${var.aws_region}-${local.stage_prefix}"
      log_stream_name = "S3Delivery"
    }

    processing_configuration {
      enabled = "false"
    }
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "waf_logs" {
  count                   = var.create && var.waf_arns != null ? length(var.waf_arns) : 0
  log_destination_configs = [concat(aws_kinesis_firehose_delivery_stream.waf_logs.*.arn, [""])[0]]
  resource_arn            = element(var.waf_arns, count.index)
}

resource "aws_cloudformation_stack" "s3_log_forwarder" {
  count        = var.create && var.waf_arns != null ? 1 : 0
  name         = join(var.delimiter, [local.module_prefix, "s3-log-forwarder"])
  capabilities = ["CAPABILITY_IAM"]

  parameters = {
    bucketName = var.cloudtrail_name != null ? var.cloudtrail_log_bucket_id : concat(aws_s3_bucket.default.*.id, [""])[0]
    kmsKey     = var.kinesis_kms_key == null ? concat(aws_kms_key.default.*.arn, [""])[0] : var.kinesis_kms_key
    prefixPath = replace(local.waf_log_prefix, "/[/]$/", "")
  }


  template_url = "https://arcticwolf-public.s3.us-west-2.amazonaws.com/install/aws-templates/us001/latest/awn_s3_template.json"

  depends_on = [
    aws_kinesis_firehose_delivery_stream.waf_logs,
  ]
}

# CSPM

resource "aws_iam_role" "cspm" {
  count       = var.create && var.enable_cspm ? 1 : 0
  name        = "AWNSecurityAuditRole"
  tags        = local.tags
  description = "${var.desc_prefix} Role for Arctic Wolf to assume to perform CSPM Audit"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "arn:aws:iam::850827386003:root"
      },
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "${var.account_id}"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "cspm" {
  count      = var.create && var.enable_cspm ? 1 : 0
  role       = concat(aws_iam_role.cspm.*.name, [""])[0]
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

# ----------------------------------------------------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------------------------------------------------

output "cloudtrail_name" {
  value       = aws_cloudtrail.default.*.name
  description = ""
}

output "cloudtrail_stack_outputs" {
  value       = aws_cloudformation_stack.cloudtrail.*.outputs
  description = ""
}

output "guardduty_stack_outputs" {
  value       = aws_cloudformation_stack.guardduty.*.outputs
  description = ""
}

output "vpc_flow_log_stack_outputs" {
  value       = coalesce(aws_cloudformation_stack.vpc_flow_log.*.outputs, aws_cloudformation_stack.vpc_flow_log_group.*.outputs)
  description = ""
}

output "kenisis_kms_key_arn" {
  value       = aws_kms_key.default.*.arn
  description = ""
}

output "kenisis_kms_key_alias_arn" {
  value       = aws_kms_alias.default.*.arn
  description = ""
}

output "kenisis_kms_key_alias_name" {
  value       = aws_kms_alias.default.*.name
  description = ""
}

output "kenisis_aws_iam_role_arn" {
  value       = aws_iam_role.kinesis.*.arn
  description = ""
}

output "kenisis_aws_iam_role_name" {
  value       = aws_iam_role.kinesis.*.name
  description = ""
}

output "kenisis_aws_iam_role_policy_id" {
  value       = aws_iam_role_policy.kinesis.*.id
  description = ""
}

output "kenisis_aws_iam_role_policy_name" {
  value       = aws_iam_role_policy.kinesis.*.name
  description = ""
}

output "cspm_aws_iam_role_arn" {
  value       = aws_iam_role.cspm.*.arn
  description = ""
}

output "cspm_aws_iam_role_name" {
  value       = aws_iam_role.cspm.*.name
  description = ""
}

output "kenisis_firehose_delivery_stream_arn" {
  value       = aws_kinesis_firehose_delivery_stream.waf_logs.*.arn
  description = ""
}

output "kenisis_firehose_delivery_stream_name" {
  value       = aws_kinesis_firehose_delivery_stream.waf_logs.*.name
  description = ""
}
