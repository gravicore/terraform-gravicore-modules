# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "security_groups" {
  type        = "list"
  default     = []
  description = "AWS security group ids"
}

variable "maintenance_window" {
  default     = "wed:03:00-wed:04:00"
  description = "(Optional) Specifies the weekly time range for when maintenance on the cache cluster is performed. The format is ddd:hh24:mi-ddd:hh24:mi (24H Clock UTC). The minimum maintenance window is a 60 minute period. Example: sun:05:00-sun:09:00"
}

variable "cluster_size" {
  default     = "1"
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
  description = "A list of Redis parameters to apply. Note that parameters may differ from one Redis family to another"
  type        = "list"
  default     = []
}

variable "engine_version" {
  default     = "4.0.10"
  description = " (Optional) Version number of the cache engine to be used. See Describe Cache Engine Versions in the AWS Documentation center for supported versions. https://docs.aws.amazon.com/cli/latest/reference/elasticache/describe-cache-engine-versions.html"
}

variable "at_rest_encryption_enabled" {
  default     = "true"
  description = "Enable encryption at rest"
}

variable "transit_encryption_enabled" {
  default     = "true"
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
  type        = "list"
  description = "Alarm action list"
  default     = []
}

variable "ok_actions" {
  type        = "list"
  description = "The list of actions to execute when this alarm transitions into an OK state from any other state. Each action is specified as an Amazon Resource Number (ARN)"
  default     = []
}

variable "apply_immediately" {
  default     = "true"
  description = "Apply changes immediately"
}

variable "automatic_failover" {
  default     = "true"
  description = "Automatic failover (Not available for T1/T2 instances)"
}

variable "availability_zones" {
  type        = "list"
  description = "Availability zone ids"
  default     = []
}

variable "zone_id" {
  default     = ""
  description = "Route53 DNS Zone id"
}

variable "delimiter" {
  type        = "string"
  default     = "-"
  description = "Delimiter between `name`, `namespace`, `stage` and `attributes`"
}

variable "attributes" {
  type        = "list"
  description = "Additional attributes (_e.g._ \"1\")"
  default     = []
}

variable "auth_token" {
  type        = "string"
  description = "Auth token for password protecting redis, transit_encryption_enabled must be set to 'true'! Password must be longer than 16 chars"
  default     = ""
}

variable "replication_group_id" {
  type        = "string"
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

  config {
    region         = "${var.aws_region}"
    bucket         = "${var.namespace}-master-prd-tf-state-${var.master_account_id}"
    encrypt        = true
    key            = "${local.remote_state_account_key}"
    dynamodb_table = "${local.remote_state_account_dynamodb_table}"
    role_arn       = "arn:aws:iam::${var.master_account_id}:role/grv_deploy_svc"
  }
}

locals {
  remote_state_vpc_key            = "${var.environment}/${var.stage}/vpc/terraform.tfstate"
  remote_state_vpc_dynamodb_table = "${var.namespace}-master-prd-tf-state-lock"
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    region         = "${var.aws_region}"
    bucket         = "${var.namespace}-master-prd-tf-state-${var.master_account_id}"
    encrypt        = true
    key            = "${local.remote_state_vpc_key}"
    dynamodb_table = "${local.remote_state_vpc_dynamodb_table}"
    role_arn       = "arn:aws:iam::${var.master_account_id}:role/grv_deploy_svc"
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

// Generate a random string for auth token, no special chars
resource "random_string" "auth_token" {
  length  = 64
  special = false
}

# module "redis" {
#   source    = "git::https://github.com/cloudposse/terraform-aws-elasticache-redis.git?ref=tags/0.9.0"
#   enabled   = "${var.create}"
#   namespace = ""
#   stage     = ""
#   name      = "${local.module_prefix}-db"
#   tags      = "${local.tags}"

#   auth_token           = "${random_string.auth_token.result}"
#   zone_id              = "${data.terraform_remote_state.vpc.vpc_dns_zone_id}"
#   vpc_id               = "${data.terraform_remote_state.vpc.vpc_id}"
#   subnets              = "${data.terraform_remote_state.vpc.vpc_private_subnets}"
#   maintenance_window   = "${var.maintenance_window}"
#   cluster_size         = "${var.cluster_size}"
#   instance_type        = "${var.instance_type}"
#   apply_immediately    = "${var.apply_immediately}"
#   availability_zones   = "${local.availability_zones}"
#   automatic_failover   = "${var.automatic_failover}"
#   replication_group_id = "${substr(replace(local.module_prefix, "-", ""), 0, 20)}"

#   # replication_group_id = "${local.module_prefix}"

#   engine_version               = "${var.engine_version}"
#   family                       = "${var.family}"
#   port                         = "${var.port}"
#   alarm_cpu_threshold_percent  = "${var.alarm_cpu_threshold_percent}"
#   alarm_memory_threshold_bytes = "${var.alarm_memory_threshold_bytes}"
#   at_rest_encryption_enabled   = "${var.at_rest_encryption_enabled}"
#   parameter = [
#     {
#       name  = "notify-keyspace-events"
#       value = "lK"
#     },
#   ]
# }

#
# Security Group Resources
#
resource "aws_security_group" "default" {
  count       = "${var.create == "true" ? 1 : 0}"
  name        = "${local.module_prefix}"
  tags        = "${local.tags}"
  description = "${var.desc_prefix}"

  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"

  ingress {
    from_port       = "${var.port}"              # Redis
    to_port         = "${var.port}"
    protocol        = "tcp"
    security_groups = ["${var.security_groups}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elasticache_subnet_group" "default" {
  count       = "${var.create == "true" ? 1 : 0}"
  name        = "${local.module_prefix}"
  description = "${var.desc_prefix}"

  subnet_ids = ["${data.terraform_remote_state.vpc.vpc_private_subnets}"]
}

resource "aws_elasticache_parameter_group" "default" {
  count       = "${var.create == "true" ? 1 : 0}"
  name        = "${local.module_prefix}"
  description = "${var.desc_prefix}"

  family    = "${var.family}"
  parameter = "${var.parameter}"
}

resource "aws_elasticache_replication_group" "default" {
  count = "${var.create == "true" ? 1 : 0}"
  tags  = "${local.tags}"

  auth_token                    = "${random_string.auth_token.result}"
  replication_group_id          = "${length(local.stage_prefix) > 20 ? format("%.20s", replace(local.stage_prefix, "-", "")) : local.stage_prefix}"
  replication_group_description = "${local.module_prefix}"
  node_type                     = "${var.instance_type}"
  number_cache_clusters         = "${var.cluster_size}"
  port                          = "${var.port}"
  parameter_group_name          = "${aws_elasticache_parameter_group.default.name}"
  availability_zones            = ["${slice(local.availability_zones, 0, var.cluster_size)}"]
  automatic_failover_enabled    = "${var.cluster_size == 1 ? false : var.automatic_failover}"
  subnet_group_name             = "${aws_elasticache_subnet_group.default.name}"
  security_group_ids            = ["${aws_security_group.default.id}"]
  maintenance_window            = "${var.maintenance_window}"
  notification_topic_arn        = "${var.notification_topic_arn}"
  engine_version                = "${var.engine_version}"
  at_rest_encryption_enabled    = "${var.at_rest_encryption_enabled}"
  transit_encryption_enabled    = "${var.transit_encryption_enabled}"
}

#
# CloudWatch Resources
#
resource "aws_cloudwatch_metric_alarm" "cache_cpu" {
  count               = "${var.create == "true" ? 1 : 0}"
  alarm_name          = "${local.module_prefix}-cpu-utilization"
  alarm_description   = "${var.desc_prefix} Redis cluster CPU utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"

  threshold = "${var.alarm_cpu_threshold_percent}"

  dimensions {
    CacheClusterId = "${local.module_prefix}"
  }

  alarm_actions = ["${var.alarm_actions}"]
  ok_actions    = ["${var.ok_actions}"]
  depends_on    = ["aws_elasticache_replication_group.default"]
}

resource "aws_cloudwatch_metric_alarm" "cache_memory" {
  count               = "${var.create == "true" ? 1 : 0}"
  alarm_name          = "${local.module_prefix}-freeable-memory"
  alarm_description   = "${var.desc_prefix} Redis cluster freeable memory"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/ElastiCache"
  period              = "60"
  statistic           = "Average"

  threshold = "${var.alarm_memory_threshold_bytes}"

  dimensions {
    CacheClusterId = "${local.module_prefix}"
  }

  alarm_actions = ["${var.alarm_actions}"]
  ok_actions    = ["${var.ok_actions}"]
  depends_on    = ["aws_elasticache_replication_group.default"]
}

module "dns" {
  source    = "git::https://github.com/cloudposse/terraform-aws-route53-cluster-hostname.git?ref=tags/0.2.1"
  enabled   = "${var.create == "true" && length(data.terraform_remote_state.vpc.vpc_dns_zone_id) > 0 ? "true" : "false"}"
  namespace = ""
  stage     = ""
  name      = "${var.name}"

  providers = {
    aws = "aws.master"
  }

  ttl     = 60
  zone_id = "${data.terraform_remote_state.vpc.vpc_dns_zone_id}"
  records = ["${aws_elasticache_replication_group.default.*.primary_endpoint_address}"]
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "tags" {
  value = "${local.tags}"
}

output "auth_token" {
  value = "${random_string.auth_token.result}"
}

output "id" {
  description = "Redis cluster id"
  value       = "${join("", aws_elasticache_replication_group.default.*.id)}"
}

output "security_group_id" {
  description = "Security group id"
  value       = "${join("", aws_security_group.default.*.id)}"
}

output "port" {
  description = "Redis port"
  value       = "${var.port}"
}

output "host" {
  description = "Redis host"
  value       = "${module.dns.hostname}"
}
