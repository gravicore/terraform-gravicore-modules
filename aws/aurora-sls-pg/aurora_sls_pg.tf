# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "zone_id" {
  type        = string
  default     = ""
  description = "Route53 parent zone ID. If provided (not empty), the module will create sub-domain DNS records for the DB master and replicas"
}

variable "security_groups" {
  type        = list(string)
  default     = []
  description = "List of security groups to be allowed to connect to the DB instance"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID to create the cluster in (e.g. `vpc-a22222ee`)"
}

variable "subnets" {
  type        = list(string)
  description = "List of VPC subnet IDs"
}

variable "db_subnet_group_name" {
  type        = string
  default     = null
  description = "(Optional) A DB subnet group to associate with this DB instance. NOTE: This must match the db_subnet_group_name specified on every aws_rds_cluster_instance in the cluster"
}

variable "db_cluster_parameter_group_name" {
  type        = string
  default     = null
  description = "(Optional) The name of the DB parameter group to associate with this instance."
}

variable "cluster_identifier" {
  type        = string
  default     = ""
  description = "The RDS Cluster Identifier. Will use generated label ID if not supplied"
}

variable "snapshot_identifier" {
  type        = string
  default     = ""
  description = "Specifies whether or not to create this cluster from a snapshot"
}

variable "db_name" {
  type        = string
  default     = ""
  description = "Database name (default is not to create a database)"
}

variable "db_port" {
  type        = number
  default     = 5432
  description = "Database port"
}

variable "admin_user" {
  type        = string
  default     = ""
  description = "(Required unless a snapshot_identifier is provided) Username for the master DB user"
}

variable "admin_password" {
  type        = string
  default     = ""
  description = "(Required unless a snapshot_identifier is provided) Password for the master DB user"
}

variable "retention_period" {
  type        = number
  default     = 7
  description = "Number of days to retain backups for"
}

variable "backup_window" {
  type        = string
  default     = "07:55-08:25"
  description = "Daily time range during which the backups happen"
}

variable "maintenance_window" {
  type        = string
  default     = "sat:03:00-sat:04:00"
  description = "Weekly time range during which system maintenance can occur, in UTC"
}

variable "cluster_parameters" {
  type = list(object({
    apply_method = string
    name         = string
    value        = string
  }))
  default     = []
  description = "List of DB cluster parameters to apply"
}

variable "instance_parameters" {
  type = list(object({
    apply_method = string
    name         = string
    value        = string
  }))
  default     = []
  description = "List of DB instance parameters to apply"
}

variable "cluster_family" {
  type        = string
  default     = "aurora-postgresql10"
  description = "The family of the DB cluster parameter group"
}

variable "engine" {
  type        = string
  default     = "aurora-postgresql"
  description = "The name of the database engine to be used for this DB cluster. Valid values: `aurora`, `aurora-mysql`, `aurora-postgresql`"
}

variable "engine_mode" {
  type        = string
  default     = "serverless"
  description = "The database engine mode. Valid values: `parallelquery`, `provisioned`, `serverless`"
}

variable "engine_version" {
  type        = string
  default     = ""
  description = "The version of the database engine to use. See `aws rds describe-db-engine-versions` "
}

variable "scaling_configuration" {
  type = list(object({
    auto_pause               = bool
    max_capacity             = number
    min_capacity             = number
    seconds_until_auto_pause = number
    timeout_action           = string
  }))
  default     = []
  description = "List of nested attributes with scaling properties. Only valid when `engine_mode` is set to `serverless`"
}

variable "timeouts_configuration" {
  type = list(object({
    create = string
    update = string
    delete = string
  }))
  default     = []
  description = "List of timeout values per action. Only valid actions are `create`, `update` and `delete`"
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  default     = []
  description = "List of CIDR blocks allowed to access the cluster"
}

variable "storage_encrypted" {
  type        = bool
  description = "Specifies whether the DB cluster is encrypted. The default is `false` for `provisioned` `engine_mode` and `true` for `serverless` `engine_mode`"
  default     = false
}

variable "kms_key_arn" {
  type        = string
  description = "The ARN for the KMS encryption key. When specifying `kms_key_arn`, `storage_encrypted` needs to be set to `true`"
  default     = ""
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Determines whether a final DB snapshot is created before the DB cluster is deleted"
  default     = true
}

variable "copy_tags_to_snapshot" {
  type        = bool
  description = "Copy tags to backup snapshots"
  default     = false
}

variable "deletion_protection" {
  type        = bool
  description = "If the DB instance should have deletion protection enabled"
  default     = false
}

variable "apply_immediately" {
  type        = bool
  description = "Specifies whether any cluster modifications are applied immediately, or during the next maintenance window"
  default     = true
}

variable "iam_database_authentication_enabled" {
  type        = bool
  description = "Specifies whether or mappings of AWS Identity and Access Management (IAM) accounts to database accounts is enabled"
  default     = false
}

variable "replication_source_identifier" {
  type        = string
  description = "ARN of a source DB cluster or DB instance if this DB cluster is to be created as a Read Replica"
  default     = ""
}

variable "enabled_cloudwatch_logs_exports" {
  type        = list(string)
  description = "List of log types to export to cloudwatch. The following log types are supported: audit, error, general, slowquery"
  default     = []
}

variable "cluster_dns_name" {
  type        = string
  description = "Name of the cluster CNAME record to create in the parent DNS zone specified by `zone_id`. If left empty, the name will be auto-asigned using the format `master.var.name`"
  default     = ""
}

variable "global_cluster_identifier" {
  type        = string
  description = "ID of the Aurora global cluster"
  default     = ""
}

variable "source_region" {
  type        = string
  description = "Source Region of primary cluster, needed when using encrypted storage and region replicas"
  default     = ""
}

variable "iam_roles" {
  type        = list(string)
  description = "Iam roles for the Aurora cluster"
  default     = []
}

variable "backtrack_window" {
  type        = number
  description = "The target backtrack window, in seconds. Only available for aurora engine currently. Must be between 0 and 259200 (72 hours)"
  default     = 0
}

variable "enable_http_endpoint" {
  type        = bool
  description = "Enable HTTP endpoint (data API). Only valid when engine_mode is set to serverless"
  default     = false
}

variable "vpc_security_group_ids" {
  type        = list(string)
  description = "Additional security group IDs to apply to the cluster, in addition to the provisioned default security group with ingress traffic from existing CIDR blocks and existing security groups"

  default = []
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "default" {
  count       = var.create && var.allowed_cidr_blocks != [] ? 1 : 0
  name        = local.module_prefix
  description = "Allow inbound traffic from Security Groups and CIDRs"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = var.security_groups
  }

  ingress {
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_db_subnet_group" "default" {
  count       = var.create && var.db_subnet_group_name == null ? 1 : 0
  name        = local.module_prefix
  description = "Allowed subnets for DB cluster instances"
  subnet_ids  = var.subnets
  tags        = local.tags
}

resource "aws_rds_cluster_parameter_group" "default" {
  count       = var.create && var.db_cluster_parameter_group_name == null ? 1 : 0
  name        = local.module_prefix
  description = "DB cluster parameter group"
  family      = var.cluster_family

  dynamic "parameter" {
    for_each = var.cluster_parameters
    content {
      apply_method = lookup(parameter.value, "apply_method", null)
      name         = parameter.value.name
      value        = parameter.value.value
    }
  }

  tags = local.tags
}

resource "aws_db_parameter_group" "default" {
  count       = var.create && var.engine_mode != "serverless" ? 1 : 0
  name        = local.module_prefix
  description = "DB instance parameter group"
  family      = var.cluster_family

  dynamic "parameter" {
    for_each = var.instance_parameters
    content {
      apply_method = lookup(parameter.value, "apply_method", null)
      name         = parameter.value.name
      value        = parameter.value.value
    }
  }

  tags = local.tags
}

module "rds_creds" {
  source = "git::https://github.com/gravicore/terraform-gravicore-modules.git//aws/parameters?ref=0.20.0"
  providers = {
    aws = aws
  }
  create = var.create && var.admin_password == "" ? true : false

  namespace   = var.namespace
  environment = var.environment
  stage       = var.stage
  tags        = local.tags
  parameters = [
    "/${local.stage_prefix}/${var.name}-password",
    "/${local.stage_prefix}/${var.name}-username",
  ]
}

resource "aws_rds_cluster" "default" {
  count                               = var.create ? 1 : 0
  cluster_identifier                  = local.module_prefix
  database_name                       = var.db_name
  master_username                     = coalesce(var.admin_user, lookup(lookup(module.rds_creds.parameters, "/${local.stage_prefix}/${var.name}-username", {}), "value", ""))
  master_password                     = coalesce(var.admin_password, lookup(lookup(module.rds_creds.parameters, "/${local.stage_prefix}/${var.name}-password", {}), "value", ""))
  backup_retention_period             = var.retention_period
  preferred_backup_window             = var.backup_window
  copy_tags_to_snapshot               = var.copy_tags_to_snapshot
  final_snapshot_identifier           = var.cluster_identifier == "" ? lower(local.module_prefix) : lower(var.cluster_identifier)
  skip_final_snapshot                 = var.skip_final_snapshot
  apply_immediately                   = var.apply_immediately
  storage_encrypted                   = var.storage_encrypted
  kms_key_id                          = var.kms_key_arn
  source_region                       = var.source_region
  snapshot_identifier                 = var.snapshot_identifier
  vpc_security_group_ids              = compact(flatten([join("", aws_security_group.default.*.id), var.vpc_security_group_ids]))
  preferred_maintenance_window        = var.maintenance_window
  db_subnet_group_name                = coalesce(join("", aws_db_subnet_group.default.*.name), var.db_subnet_group_name)
  db_cluster_parameter_group_name     = coalesce(join("", aws_rds_cluster_parameter_group.default.*.name), var.db_cluster_parameter_group_name)
  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  tags                                = local.tags
  engine                              = var.engine
  engine_version                      = var.engine_version
  engine_mode                         = var.engine_mode
  global_cluster_identifier           = var.global_cluster_identifier
  iam_roles                           = var.iam_roles
  backtrack_window                    = var.backtrack_window
  enable_http_endpoint                = var.engine_mode == "serverless" && var.enable_http_endpoint ? true : false

  dynamic "scaling_configuration" {
    for_each = var.scaling_configuration
    content {
      auto_pause               = lookup(scaling_configuration.value, "auto_pause", null)
      max_capacity             = lookup(scaling_configuration.value, "max_capacity", null)
      min_capacity             = lookup(scaling_configuration.value, "min_capacity", null)
      seconds_until_auto_pause = lookup(scaling_configuration.value, "seconds_until_auto_pause", null)
      timeout_action           = lookup(scaling_configuration.value, "timeout_action", null)
    }
  }

  dynamic "timeouts" {
    for_each = var.timeouts_configuration
    content {
      create = lookup(timeouts.value, "create", "120m")
      update = lookup(timeouts.value, "update", "120m")
      delete = lookup(timeouts.value, "delete", "120m")
    }
  }

  replication_source_identifier   = var.replication_source_identifier
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  deletion_protection             = var.deletion_protection
}

locals {
  cluster_dns_name = var.cluster_dns_name != "" ? var.cluster_dns_name : local.module_prefix
}

module "dns_master" {
  source  = "git::https://github.com/cloudposse/terraform-aws-route53-cluster-hostname.git?ref=tags/0.3.0"
  enabled = var.create && length(var.zone_id) > 0 ? true : false
  name    = local.cluster_dns_name
  zone_id = var.zone_id
  records = coalescelist(aws_rds_cluster.default.*.endpoint, [""])
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "database_name" {
  value       = var.db_name
  description = "Database name"
}

output "master_username" {
  value       = join("", aws_rds_cluster.default.*.master_username)
  description = "Username for the master DB user"
}

resource "aws_ssm_parameter" "aurora_sls_pg_username" {
  count       = var.create && var.admin_user != "" ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-username"
  description = format("%s %s", var.desc_prefix, "Username for the master DB user")
  tags        = var.tags

  type  = "String"
  value = join("", aws_rds_cluster.default.*.master_username)
}

resource "aws_ssm_parameter" "aurora_sls_pg_password" {
  count       = var.create && var.admin_password != "" ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-password"
  description = format("%s %s", var.desc_prefix, "Password for the master DB user")
  tags        = var.tags

  type  = "String"
  value = var.admin_password
}

output "cluster_identifier" {
  value       = join("", aws_rds_cluster.default.*.cluster_identifier)
  description = "Cluster Identifier"
}

output "arn" {
  value       = join("", aws_rds_cluster.default.*.arn)
  description = "Amazon Resource Name (ARN) of cluster"
}

output "endpoint" {
  value       = join("", aws_rds_cluster.default.*.endpoint)
  description = "The DNS address of the RDS instance"
}

resource "aws_ssm_parameter" "aurora_sls_pg_endpoint" {
  count       = var.create ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-endpoint"
  description = format("%s %s", var.desc_prefix, "The DNS address of the RDS instance")
  tags        = var.tags

  type  = "String"
  value = join("", aws_rds_cluster.default.*.endpoint)
}

output "reader_endpoint" {
  value       = join("", aws_rds_cluster.default.*.reader_endpoint)
  description = "A read-only endpoint for the Aurora cluster, automatically load-balanced across replicas"
}

output "master_host" {
  value       = module.dns_master.hostname
  description = "DB Master hostname"
}

output "cluster_resource_id" {
  value       = join("", aws_rds_cluster.default.*.cluster_resource_id)
  description = "The region-unique, immutable identifie of the cluster"
}

output "cluster_security_groups" {
  value       = coalescelist(aws_rds_cluster.default.*.vpc_security_group_ids, [""])
  description = "Default RDS cluster security groups"
}
