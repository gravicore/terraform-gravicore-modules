# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "datasync_locations" {
  description = "Map of DataSync Locations"
  type        = map
  default     = {}
}

locals {
  datasync_locations = { for k, v in var.datasync_locations : k => merge(v, {
    subdirectory = format("/%s/", join("/", compact(split("/", v.subdirectory))))
  }) }
  datasync_locations_s3  = { for k, v in var.datasync_locations : k => v if v.type == "s3" }
  datasync_locations_smb = { for k, v in var.datasync_locations : k => v if v.type == "smb" }
  datasync_locations_fsx = { for k, v in var.datasync_locations : k => v if v.type == "fsx" }
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

# DataSync locations (S3)

resource "aws_iam_role" "datasync_s3" {
  for_each    = var.create && length(local.datasync_locations_s3) > 0 ? local.datasync_locations_s3 : {}
  name        = join("-", [local.module_prefix, "s3", each.key])
  description = join(" ", [var.desc_prefix, "Allows DataSync (${each.key}) to access S3 location"])
  tags        = local.tags

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "datasync.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "datasync_s3" {
  for_each = var.create && length(local.datasync_locations_s3) > 0 ? local.datasync_locations_s3 : {}

  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:HeadBucket",
    ]
    resources = ["arn:aws:s3:::${each.value.s3_bucket}"]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
    ]
    resources = [
      "arn:aws:s3:::${each.value.s3_bucket}${each.value.subdirectory}*",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogStream",
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "datasync_s3" {
  for_each = var.create && length(local.datasync_locations_s3) > 0 ? local.datasync_locations_s3 : {}
  name     = join("-", [local.module_prefix, "s3", each.key])

  role   = aws_iam_role.datasync_s3[each.key].id
  policy = data.aws_iam_policy_document.datasync_s3[each.key].json
}

resource "aws_datasync_location_s3" "datasync" {
  for_each = var.create && length(local.datasync_locations_s3) > 0 ? local.datasync_locations_s3 : {}
  tags     = merge(local.tags, { Name = join("-", [local.module_prefix, each.key]) })

  s3_bucket_arn = "arn:aws:s3:::${each.value.s3_bucket}"
  subdirectory  = each.value.subdirectory
  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_s3[each.key].arn
  }
}

# DataSync locations (SMB)

resource "aws_datasync_location_smb" "datasync" {
  for_each = var.create && var.datasync_agent_id != null && length(local.datasync_locations_smb) > 0 ? local.datasync_locations_smb : {}
  tags     = merge(local.tags, { Name = join("-", [local.module_prefix, each.key]) })

  server_hostname = each.value.server_hostname
  subdirectory    = each.value.subdirectory

  domain   = split("/", each.value.user)[0]
  user     = split("/", each.value.user)[1]
  password = each.value.password

  agent_arns = [local.datasync_agent_arn]
}

locals {
  datasync_locations_arns = merge(
    { for k, v in aws_datasync_location_s3.datasync : k => v.arn },
    { for k, v in aws_datasync_location_smb.datasync : k => v.arn },
  )
}

resource "aws_datasync_location_fsx_windows_file_system" "datasync" {
  for_each = var.create && var.datasync_agent_id != null && length(local.datasync_locations_fsx) > 0 ? local.datasync_locations_fsx : {}
  tags     = merge(local.tags, { Name = join("-", [local.module_prefix, each.key]) })

  fsx_filesystem_arn = each.value.fsx_filesystem_arn
  subdirectory       = lookup(each.value, "subdirectory", null)

  domain   = split("/", each.value.user)[0]
  user     = split("/", each.value.user)[1]
  password = each.value.password

  security_group_arns = lookup(each.value, "security_group_arns", null)
}

# ----------------------------------------------------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------------------------------------------------

output "datasync_locations_s3" {
  description = "S3 Locations for DataSync"
  value       = var.create && length(local.datasync_locations_s3) > 0 ? aws_datasync_location_s3.datasync : null
}

output "datasync_locations_smb" {
  description = "SMB Locations for DataSync"
  value       = var.create && var.datasync_agent_id != null && length(local.datasync_locations_smb) > 0 ? aws_datasync_location_smb.datasync : null
}

output "datasync_locations_smb" {
  description = "SMB Locations for DataSync"
  value       = var.create && var.datasync_agent_id != null && length(local.datasync_locations_fsx) > 0 ? aws_datasync_location_fsx_windows_file_system.datasync : null
}

# module "parameters_vpc" {
#   source      = "git::https://github.com/gravicore/terraform-gravicore-modules.git//aws/parameters?ref=0.32.0"
#   providers   = { aws = "aws" }
#   create      = var.create
#   namespace   = var.namespace
#   environment = var.environment
#   stage       = var.stage
#   tags        = local.tags

#   write_parameters = {
#     "/${local.stage_prefix}/lambda-role-arn" = { value = aws_iam_role.lambda[0].arn, description = "Arn of the lambda IAM role" }
#     "/${local.stage_prefix}/glue-role-arn" = { value = aws_iam_role.glue[0].arn, description = "Arn of the glue IAM role" }
#     "/${local.stage_prefix}/lambda-security-group-id" = { value = aws_security_group.lambda[0].id, description = "ID of secuirty group created for lambdas" }
#   }
# }
