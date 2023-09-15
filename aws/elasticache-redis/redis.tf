# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "security_groups" {
  type        = list(string)
  default     = []
  description = "AWS security group ids"
}

variable "auto_minor_version_upgrade" {
  type        = bool
  default     = false
  description = "Specifies whether a minor engine upgrades will be applied automatically to the underlying Cache Cluster instances during the maintenance window."
}

variable "maintenance_window" {
  default     = "wed:03:00-wed:04:00"
  description = "(Optional) Specifies the weekly time range for when maintenance on the cache cluster is performed. The format is ddd:hh24:mi-ddd:hh24:mi (24H Clock UTC). The minimum maintenance window is a 60 minute period. Example: sun:05:00-sun:09:00"
}

variable "cluster_size" {
  default     = 1
  description = "Count of nodes in cluster"
}

variable "port" {
  default     = "6379"
  description = "Redis port"
}

variable "instance_type" {
  default     = "cache.t2.micro"
  description = "Elastic cache instance type"
}

variable "family" {
  default     = "redis4.0"
  description = "Redis family "
}

variable "parameter" {
  type        = list(string)
  default     = []
  description = "A list of Redis parameters to apply. Note that parameters may differ from one Redis family to another"
}

variable "engine_version" {
  default     = "4.0.10"
  description = "Version number of the cache engine to be used. See Describe Cache Engine Versions in the AWS Documentation center for supported versions. https://docs.aws.amazon.com/cli/latest/reference/elasticache/describe-cache-engine-versions.html"
}

variable "at_rest_encryption_enabled" {
  type        = bool
  default     = true
  description = "Enable encryption at rest"
}

variable "transit_encryption_enabled" {
  type        = bool
  default     = true
  description = "Enable TLS"
}

variable "notification_topic_arn" {
  default     = ""
  description = "Notification topic arn"
}

variable "alarm_cpu_threshold_percent" {
  default     = "75"
  description = "CPU threshold alarm level"
}

variable "alarm_memory_threshold_bytes" {
  # 10MB
  default     = "10000000"
  description = "Ram threshold alarm level"
}

variable "alarm_actions" {
  type        = list(string)
  default     = []
  description = "Alarm action list"
}

variable "ok_actions" {
  type        = list(string)
  default     = []
  description = "The list of actions to execute when this alarm transitions into an OK state from any other state. Each action is specified as an Amazon Resource Number (ARN)"
}

variable "apply_immediately" {
  type        = bool
  default     = true
  description = "Apply changes immediately"
}

variable "automatic_failover" {
  type        = bool
  default     = true
  description = "Automatic failover (Not available for T1/T2 instances)"
}

variable "availability_zones" {
  type        = list(string)
  default     = []
  description = "Availability zone ids"
}

variable "zone_id" {
  default     = ""
  description = "Route53 DNS Zone id"
}

variable "dns_ttl" {
  default     = "30"
  description = "The TTL (Time to Live) of the DNS records."
}

variable "delimiter" {
  type        = string
  default     = "-"
  description = "Delimiter between `name`, `namespace`, `stage` and `attributes`"
}

variable "attributes" {
  type        = list(string)
  default     = []
  description = "Additional attributes (_e.g._ \"1\")"
}

variable "auth_token" {
  type        = string
  default     = ""
  description = "Auth token for password protecting redis, transit_encryption_enabled must be set to 'true'! Password must be longer than 16 chars"
}

variable "replication_group_id" {
  type        = string
  description = "Replication group ID with the following constraints: \nA name must contain from 1 to 20 alphanumeric characters or hyphens. \n The first character must be a letter. \n A name cannot end with a hyphen or contain two consecutive hyphens."
  default     = ""
}

locals {
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b"]
}

locals {
  remote_state_account_key            = "${var.environment}/${var.stage}/acct/terraform.tfstate"
  remote_state_account_dynamodb_table = "${var.namespace}-master-prd-tf-state-lock"
}

data "terraform_remote_state" "acct" {
  backend = "s3"

  config = {
    region         = var.aws_region
    bucket         = "${var.namespace}-master-prd-tf-state-${var.master_account_id}"
    encrypt        = true
    key            = local.remote_state_account_key
    dynamodb_table = local.remote_state_account_dynamodb_table
    role_arn       = "arn:aws:iam::${var.master_account_id}:role/grv_deploy_svc"
  }
}

locals {
  remote_state_vpc_key            = "${var.environment}/${var.stage}/vpc/terraform.tfstate"
  remote_state_vpc_dynamodb_table = "${var.namespace}-master-prd-tf-state-lock"
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    region         = var.aws_region
    bucket         = "${var.namespace}-master-prd-tf-state-${var.master_account_id}"
    encrypt        = true
    key            = local.remote_state_vpc_key
    dynamodb_table = local.remote_state_vpc_dynamodb_table
    role_arn       = "arn:aws:iam::${var.master_account_id}:role/grv_deploy_svc"
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

// Generate a random string for auth token, no special chars
resource "random_string" "auth_token" {
  count   = var.create && var.transit_encryption_enabled ? 1 : 0
  length  = 64
  special = true
}

#
# Security Group Resources
#

resource "aws_security_group" "default" {
  count       = var.create ? 1 : 0
  name        = local.module_prefix
  tags        = local.tags
  description = var.desc_prefix

  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    from_port       = var.port # Redis
    to_port         = var.port
    protocol        = "tcp"
    security_groups = var.security_groups
    description     = "${var.desc_prefix} ElastiCache Redis TCP Port"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "${var.desc_prefix} Allow All"
  }
}

resource "aws_elasticache_subnet_group" "default" {
  count       = var.create ? 1 : 0
  name        = local.module_prefix
  description = var.desc_prefix

  subnet_ids = data.terraform_remote_state.vpc.outputs.vpc_private_subnets
}

resource "aws_elasticache_parameter_group" "default" {
  count       = var.create ? 1 : 0
  name        = local.module_prefix
  description = var.desc_prefix

  family = var.family
  dynamic "parameter" {
    for_each = var.parameter
    content {
      # TF-UPGRADE-TODO: The automatic upgrade tool can't predict
      # which keys might be set in maps assigned here, so it has
      # produced a comprehensive set here. Consider simplifying
      # this after confirming which keys can be set in practice.

      name  = parameter.value.name
      value = parameter.value.value
    }
  }
}

# Transit encryption enabled
resource "aws_elasticache_replication_group" "default" {
  count = var.create && var.transit_encryption_enabled == false ? 1 : 0
  tags  = local.tags

  # auth_token                    = "${var.transit_encryption_enabled ? join("", random_string.auth_token.*.result) : ""}"
  replication_group_id          = length(local.stage_prefix) > 20 ? format("%.20s", replace(local.stage_prefix, "-", "")) : local.stage_prefix
  replication_group_description = join(" ", [var.desc_prefix, local.stage_prefix])
  node_type                     = var.instance_type
  number_cache_clusters         = var.cluster_size
  port                          = var.port
  parameter_group_name          = aws_elasticache_parameter_group.default[0].name
  availability_zones            = slice(local.availability_zones, 0, var.cluster_size)
  automatic_failover_enabled    = var.cluster_size == 1 ? false : var.automatic_failover
  subnet_group_name             = aws_elasticache_subnet_group.default[0].name
  security_group_ids            = [aws_security_group.default[0].id]
  maintenance_window            = var.maintenance_window
  notification_topic_arn        = var.notification_topic_arn
  engine_version                = var.engine_version
  at_rest_encryption_enabled    = var.at_rest_encryption_enabled
  transit_encryption_enabled    = var.transit_encryption_enabled
  auto_minor_version_upgrade    = var.auto_minor_version_upgrade
}

#
# CloudWatch Resources
#
resource "aws_cloudwatch_metric_alarm" "cache_cpu" {
  count               = var.create ? 1 : 0
  alarm_name          = "${local.module_prefix}-cpu-utilization"
  alarm_description   = "${var.desc_prefix} Redis cluster CPU utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"

  threshold = var.alarm_cpu_threshold_percent

  dimensions = {
    CacheClusterId = local.module_prefix
  }

  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions
  depends_on    = [aws_elasticache_replication_group.default]
}

resource "aws_cloudwatch_metric_alarm" "cache_memory" {
  count               = var.create ? 1 : 0
  alarm_name          = "${local.module_prefix}-freeable-memory"
  alarm_description   = "${var.desc_prefix} Redis cluster freeable memory"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/ElastiCache"
  period              = "60"
  statistic           = "Average"

  threshold = var.alarm_memory_threshold_bytes

  dimensions = {
    CacheClusterId = local.module_prefix
  }

  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions
  depends_on    = [aws_elasticache_replication_group.default]
}

module "dns" {
  source  = "git::https://github.com/cloudposse/terraform-aws-route53-cluster-hostname.git?ref=tags/0.3.0"
  enabled = var.create && length(data.terraform_remote_state.vpc.outputs.vpc_dns_zone_id) > 0 ? true : false
  # namespace = ""
  # stage     = ""
  name = var.name

  providers = {
    aws = aws.master
  }

  ttl     = var.dns_ttl
  zone_id = data.terraform_remote_state.vpc.outputs.vpc_dns_zone_id
  records = aws_elasticache_replication_group.default.*.primary_endpoint_address
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

locals {
  module_ssm_parameters_tags = merge(
    local.tags,
    {
      "TerraformModule"        = "cloudposse/terraform-aws-ssm-parameter-store"
      "TerraformModuleVersion" = "0.1.5"
    },
  )
}

# module "params" {
#   source = "git::https://github.com/cloudposse/terraform-aws-ssm-parameter-store?ref=0.1.5"
#   tags   = "${local.module_ssm_parameters_tags}"

#   kms_arn = "alias/parameter_store_key"

#   parameter_write = [
#     {
#       name        = "/${local.stage_prefix}/${var.name}-elasticache-replication-group-id"
#       value       = "${join("", aws_elasticache_replication_group.default.*.id)}"
#       type        = "String"
#       overwrite   = "true"
#       description = "${join(": ", list(var.desc_prefix, "The identifier for the replication group."))}"
#     },
#     {
#       name        = "/${local.stage_prefix}/${var.name}-security-group-id"
#       value       = "${join("", aws_security_group.default.*.id)}"
#       type        = "String"
#       overwrite   = "true"
#       description = "${join(": ", list(var.desc_prefix, "The ID of the security group."))}"
#     },
#     {
#       name        = "/${local.stage_prefix}/${var.name}-elasticache-subnet-group-name"
#       value       = "${join("", aws_elasticache_subnet_group.default.*.name)}"
#       type        = "String"
#       overwrite   = "true"
#       description = "${join(": ", list(var.desc_prefix, "Name for the cache subnet group."))}"
#     },
#   ]

#   # {
#   #   name        = "/${local.stage_prefix}/${var.name}-elasticache-subnet-group-subnet-ids"
#   #   value       = "${aws_elasticache_subnet_group.default.subnet_ids.*.id}"
#   #   type        = "String"
#   #   overwrite   = "true"
#   #   description = "${join(": ", list(var.desc_prefix, "List of VPC Subnet IDs for the cache subnet group."))}"
#   # },
# }

output "apply_immediately" {
  value       = var.apply_immediately
  description = "Specifies whether any modifications are applied immediately, or during the next maintenance window."
}

output "at_rest_encryption_enabled" {
  value = join(
    "",
    aws_elasticache_replication_group.default.*.at_rest_encryption_enabled,
  )
  description = "Whether to enable encryption at rest."
}

output "auth_token" {
  value       = var.transit_encryption_enabled ? join("", random_string.auth_token.*.result) : ""
  description = "The password used to access a password protected server."
}

module "params_auth_token" {
  source  = "git::https://github.com/cloudposse/terraform-aws-ssm-parameter-store?ref=0.1.5"
  enabled = var.transit_encryption_enabled
  tags    = local.module_ssm_parameters_tags

  kms_arn = "alias/parameter_store_key"

  parameter_write = [
    {
      name      = "/${local.stage_prefix}/${var.name}-auth-token"
      value     = join("", random_string.auth_token.*.result)
      type      = "SecureString"
      overwrite = "true"
      description = join(
        " ",
        [
          var.desc_prefix,
          "The password used to access a password protected server.",
        ],
      )
    },
  ]
}

output "automatic_failover_enabled" {
  value = join(
    "",
    aws_elasticache_replication_group.default.*.automatic_failover_enabled,
  )
  description = "Specifies whether a read-only replica will be automatically promoted to read/write primary if the existing primary fails. If true, Multi-AZ is enabled for this replication group. If false, Multi-AZ is disabled for this replication group. Must be enabled for Redis (cluster mode enabled) replication groups. Defaults to false."
}

output "availability_zones" {
  value = flatten(
    aws_elasticache_replication_group.default.*.availability_zones,
  )
  description = "A list of EC2 availability zones in which the replication group's cache clusters will be created. The order of the availability zones in the list is not important."
}

output "cluster_mode" {
  value       = flatten(aws_elasticache_replication_group.default.*.cluster_mode)
  description = "Create a native redis cluster. automatic_failover_enabled must be set to true. Cluster Mode documented below. Only 1 cluster_mode block is allowed."
}

output "dns_hostname" {
  value       = module.dns.hostname
  description = "The Redis DNS ."
}

output "engine" {
  value       = join("", aws_elasticache_replication_group.default.*.engine)
  description = "The name of the cache engine to be used for the clusters in this replication group."
}

output "engine_version" {
  value = join(
    "",
    aws_elasticache_replication_group.default.*.engine_version,
  )
  description = "The version number of the cache engine to be used for the cache clusters in this replication group."
}

output "id" {
  value       = join("", aws_elasticache_replication_group.default.*.id)
  description = "The identifier for the replication group."
}

output "maintenance_window" {
  value = join(
    "",
    aws_elasticache_replication_group.default.*.maintenance_window,
  )
  description = "Specifies the weekly time range for when maintenance on the cache cluster is performed. The format is ddd:hh24:mi-ddd:hh24:mi (24H Clock UTC). The minimum maintenance window is a 60 minute period. Example: sun:05:00-sun:09:00."
}

output "member_clusters" {
  value       = flatten(aws_elasticache_replication_group.default.*.member_clusters)
  description = "The identifiers of all the nodes that are part of this replication group."
}

output "notification_topic_arn" {
  value       = var.notification_topic_arn
  description = "An Amazon Resource Name (ARN) of an SNS topic to send ElastiCache notifications to. Example: arn:aws:sns:us-east-1:012345678999:my_sns_topic."
}

output "node_type" {
  value       = join("", aws_elasticache_replication_group.default.*.node_type)
  description = "The compute and memory capacity of the nodes in the node group."
}

output "number_cache_clusters" {
  value = join(
    "",
    aws_elasticache_replication_group.default.*.number_cache_clusters,
  )
  description = "The number of cache clusters (primary and replicas) this replication group will have. If Multi-AZ is enabled, the value of this parameter must be at least 2. Updates will occur before other modifications."
}

output "parameter_group_name" {
  value = join(
    "",
    aws_elasticache_replication_group.default.*.parameter_group_name,
  )
  description = "The name of the parameter group to associate with this replication group. If this argument is omitted, the default cache parameter group for the specified engine is used."
}

output "primary_endpoint_address" {
  value = join(
    "",
    aws_elasticache_replication_group.default.*.primary_endpoint_address,
  )
  description = "The address of the endpoint for the primary node in the replication group."
}

output "port" {
  value       = join("", aws_elasticache_replication_group.default.*.port)
  description = "The port number on which each of the cache nodes will accept connections."
}

output "security_group_names" {
  value = flatten(
    aws_elasticache_replication_group.default.*.security_group_names,
  )
  description = "A list of cache security group names to associate with this replication group."
}

output "security_group_ids" {
  value = flatten(
    aws_elasticache_replication_group.default.*.security_group_ids,
  )
  description = "One or more Amazon VPC security groups associated with this replication group. Use this parameter only when you are creating a replication group in an Amazon VPC."
}

output "snapshot_retention_limit" {
  value = join(
    "",
    aws_elasticache_replication_group.default.*.snapshot_retention_limit,
  )
  description = "The number of days for which ElastiCache will retain automatic cache cluster snapshots before deleting them. For example, if you set SnapshotRetentionLimit to 5, then a snapshot that was taken today will be retained for 5 days before being deleted. If the value of SnapshotRetentionLimit is set to zero (0), backups are turned off. Please note that setting a snapshot_retention_limit is not supported on cache.t1.micro or cache.t2.* cache nodes."
}

output "snapshot_window" {
  value = join(
    "",
    aws_elasticache_replication_group.default.*.snapshot_window,
  )
  description = "The daily time range (in UTC) during which ElastiCache will begin taking a daily snapshot of your cache cluster. The minimum snapshot window is a 60 minute period. Example: 05:00-09:00."
}

output "subnet_group_name" {
  value = join(
    "",
    aws_elasticache_replication_group.default.*.subnet_group_name,
  )
  description = "The name of the cache subnet group to be used for the replication group."
}

output "subnet_group_subnet_ids" {
  value       = flatten(aws_elasticache_subnet_group.default.*.subnet_ids)
  description = "List of VPC Subnet IDs for the cache subnet group."
}

output "tags" {
  value       = local.tags
  description = "A mapping of tags to assign to the resource."
}

output "transit_encryption_enabled" {
  value = join(
    "",
    aws_elasticache_replication_group.default.*.transit_encryption_enabled,
  )
  description = "Whether to enable encryption in transit."
}

