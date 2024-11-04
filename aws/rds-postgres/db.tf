# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "identifier" {
  description = "The name of the RDS instance, if omitted, Terraform will assign a random, unique identifier"
  default     = []
  type        = list(string)

}

variable "allocated_storage" {
  description = "The allocated storage in gigabytes"
}

variable "max_allocated_storage" {
  type        = number
  default     = 0
  description = "(Optional) When configured, the upper limit to which Amazon RDS can automatically scale the storage of the DB instance. Configuring this will automatically ignore differences to allocated_storage. Must be greater than or equal to allocated_storage or 0 to disable Storage Autoscaling"
}

variable "storage_type" {
  description = "One of 'standard' (magnetic), 'gp2' (general purpose SSD), or 'io1' (provisioned IOPS SSD). The default is 'io1' if iops is specified, 'standard' if not. Note that this behaviour is different from the AWS web console, where the default is 'gp2'."
  default     = "gp2"
}

variable "storage_encrypted" {
  description = "Specifies whether the DB instance is encrypted"
  default     = false
}

variable "kms_key_id" {
  description = "The ARN for the KMS encryption key. If creating an encrypted replica, set this to the destination KMS ARN. If storage_encrypted is set to true and kms_key_id is not specified the default KMS key created in your account will be used"
  default     = ""
}

variable "replicate_source_db" {
  description = "Specifies that this resource is a Replicate database, and to use this value as the source database. This correlates to the identifier of another Amazon RDS Database to replicate."
  default     = null
}

variable "snapshot_identifier" {
  description = "Specifies whether or not to create this database from a snapshot. This correlates to the snapshot ID you'd find in the RDS console, e.g: rds:production-2015-06-26-06-05."
  default     = null
}

variable "license_model" {
  description = "License model information for this DB instance. Optional, but required for some DB engines, i.e. Oracle SE1"
  default     = ""
}

variable "iam_database_authentication_enabled" {
  description = "Specifies whether or mappings of AWS Identity and Access Management (IAM) accounts to database accounts is enabled"
  default     = false
}

variable "engine" {
  description = "The database engine to use"
  default     = "postgres"
}

variable "engine_version" {
  description = "The engine version to use"
}

variable "final_snapshot_identifier" {
  description = "The name of your final DB snapshot when this DB instance is deleted."
  default     = false
}

variable "instance_class" {
  description = "The instance type of the RDS instance"
}

variable "db_name" {
  description = "The DB name to create. If omitted, no database is created initially"
  default     = null
}

variable "username" {
  description = "Username for the master DB user"
  default     = ""
}

variable "password" {
  description = "Password for the master DB user. Note that this may show up in logs, and it will be stored in the state file"
  default     = ""
}

variable "port" {
  description = "The port on which the DB accepts connections"
  default     = "5432"
}

variable "vpc_security_group_ids" {
  type        = list(string)
  description = "List of VPC security groups to associate"
  default     = []
}

variable "db_subnet_group_name" {
  description = "Name of DB subnet group. DB instance will be created in the VPC associated with the DB subnet group. If unspecified, will be created in the default VPC"
  default     = ""
}

variable "parameter_group_name" {
  description = "Name of the DB parameter group to associate. Setting this automatically disables parameter_group creation"
  default     = ""
}

variable "availability_zone" {
  description = "The Availability Zone of the RDS instance"
  default     = ""
}

variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ"
  default     = false
}

variable "iops" {
  description = "The amount of provisioned IOPS. Setting this implies a storage_type of 'io1'"
  default     = 0
}

variable "publicly_accessible" {
  description = "Bool to control if instance is publicly accessible"
  default     = false
}

variable "enable_iam_s3_import" {
  description = "Whether to crate and add s3 import IAM role to RDS instance"
  default     = true
  type        = bool
}

variable "monitoring_interval" {
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance. To disable collecting Enhanced Monitoring metrics, specify 0. The default is 0. Valid Values: 0, 1, 5, 10, 15, 30, 60."
  default     = 0
}

variable "monitoring_role_arn" {
  description = "The ARN for the IAM role that permits RDS to send enhanced monitoring metrics to CloudWatch Logs. Must be specified if monitoring_interval is non-zero."
  default     = ""
}

variable "monitoring_role_name" {
  description = "Name of the IAM role which will be created when create_monitoring_role is enabled."
  default     = "rds-monitoring-role"
}

variable "create_monitoring_role" {
  description = "Create IAM role with a defined name that permits RDS to send enhanced monitoring metrics to CloudWatch Logs."
  default     = false
}

variable "allow_major_version_upgrade" {
  description = "Indicates that major version upgrades are allowed. Changing this parameter does not result in an outage and the change is asynchronously applied as soon as possible"
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "Indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window"
  default     = true
}

variable "apply_immediately" {
  description = "Specifies whether any database modifications are applied immediately, or during the next maintenance window"
  default     = false
}

variable "maintenance_window" {
  description = "The window to perform maintenance in. Syntax: 'ddd:hh24:mi-ddd:hh24:mi'. Eg: 'Mon:00:00-Mon:03:00'"
}

variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted. If true is specified, no DBSnapshot is created. If false is specified, a DB snapshot is created before the DB instance is deleted, using the value from final_snapshot_identifier"
  default     = true
}

variable "copy_tags_to_snapshot" {
  description = "On delete, copy all Instance tags to the final snapshot (if final_snapshot_identifier is specified)"
  default     = false
}

variable "backup_retention_period" {
  description = "The days to retain backups for"
  default     = 1
}

variable "backup_window" {
  description = "The daily time range (in UTC) during which automated backups are created if they are enabled. Example: '09:46-10:16'. Must not overlap with maintenance_window"
}

# DB subnet group
variable "subnet_ids" {
  type        = list(string)
  description = "A list of VPC subnet IDs"
  default     = []
}

# DB parameter group
variable "family" {
  description = "The family of the DB parameter group"
  default     = ""
}

variable "parameters" {
  description = "A list of DB parameters (map) to apply"
  default     = []
}

# DB parameter group
variable "ingress_sg_cidr" {
  description = "List of the ingress cidr's to create the security group."
  default     = []
  type        = list(string)
}

variable "egress_sg_cidr" {
  description = "List of the egress cidr's to create the security group."
  default     = []
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC to create the security group in."
  default     = ""
}

variable "create_db_subnet_group" {
  description = "Whether to create a database subnet group"
  default     = true
}

variable "create_db_parameter_group" {
  description = "Whether to create a database parameter group"
  default     = true
}

variable "create_db_security_group" {
  description = "Whether to create a database VPC security group"
  default     = true
}

variable "create_db_instance" {
  description = "Whether to create a database instance"
  default     = true
}

variable "timezone" {
  description = "(Optional) Time zone of the DB instance. timezone is currently only supported by Microsoft SQL Server. The timezone can only be set on creation. See MSSQL User Guide for more information."
  default     = ""
}

variable "character_set_name" {
  description = "(Optional) The character set name to use for DB encoding in Oracle instances. This can't be changed. See Oracle Character Sets Supported in Amazon RDS for more information."
  default     = ""
}

variable "deletion_protection" {
  description = "(Optional) If the DB instance should have deletion protection enabled. The database can't be deleted when this value is set to true. The default is false."
  default     = false
}

variable "schedule" {
  description = "(Optional) Which schedule from the instance scheduler to adhere to"
}

variable "enabled_cloudwatch_logs_exports" {
  type        = list(string)
  default     = ["postgresql", "upgrade"]
  description = "(Optional) List of log types to enable for exporting to CloudWatch logs. If omitted, no logs will be exported. Valid values (depending on engine): agent (MSSQL), alert, audit, error, general, listener, slowquery, trace, postgresql (PostgreSQL), upgrade (PostgreSQL)."
}

variable "performance_insights_enabled" {
  description = "(Optional) Specifies whether Performance Insights are enabled. Defaults to false"
  default     = false
  type        = bool
}

variable "performance_insights_kms_key_id" {
  description = "(Optional) The ARN for the KMS key to encrypt Performance Insights data. When specifying performance_insights_kms_key_id, performance_insights_enabled needs to be set to true. Once KMS key is set, it can never be changed"
  default     = ""
  type        = string
}

variable "performance_insights_retention_period" {
  description = "(Optional) The amount of time in days to retain Performance Insights data. Either 7 (7 days) or 731 (2 years). When specifying performance_insights_retention_period, performance_insights_enabled needs to be set to true. Defaults to '7'"
  default     = 7
  type        = number
}

locals {
  db_subnet_group_name = coalesce(
    var.db_subnet_group_name,
    module.db_subnet_group.this_db_subnet_group_id,
  )
  enable_create_db_subnet_group = var.db_subnet_group_name == "" ? var.create_db_subnet_group : false
  parameter_group_name = coalesce(
    var.parameter_group_name,
    module.db_parameter_group.this_db_parameter_group_id,
  )
  enable_create_db_parameter_group = var.parameter_group_name == "" ? var.create_db_parameter_group : false
  enable_create_security_group     = var.vpc_id != "" ? var.create_db_security_group : false
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------
data "aws_kms_key" "parameter_store_key" {
  key_id = "alias/parameter_store_key"
}

module "rds_ssm_param_secret" {
  enabled        = var.password == "" ? "true" : "false"
  source         = "git::https://github.com/cloudposse/terraform-aws-ssm-parameter-store?ref=0.4.2"
  kms_arn        = "alias/parameter_store_key"
  parameter_read = ["/${local.stage_prefix}/${var.name}-password"]
}

module "rds_ssm_param_username" {
  enabled        = var.username == "" ? "true" : "false"
  source         = "git::https://github.com/cloudposse/terraform-aws-ssm-parameter-store?ref=0.4.2"
  parameter_read = ["/${local.stage_prefix}/${var.name}-username"]
}


resource "aws_security_group" "this" {
  count       = local.enable_create_security_group ? 1 : 0
  name        = local.module_prefix
  description = "Allow internal and VPN traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.port
    to_port     = var.port
    protocol    = "6"
    cidr_blocks = var.ingress_sg_cidr
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = coalescelist(var.egress_sg_cidr, var.ingress_sg_cidr)
  }

  lifecycle {
    ignore_changes        = [ingress]
    create_before_destroy = true
  }
}

module "db_subnet_group" {
  source        = "./modules/db-subnet-group"
  create        = local.enable_create_db_subnet_group
  module_prefix = local.module_prefix
  subnet_ids    = var.subnet_ids
  tags          = local.tags
}

module "db_parameter_group" {
  source        = "./modules/db-parameter-group"
  create        = local.enable_create_db_parameter_group
  module_prefix = "${local.module_prefix}-${var.family}"
  family        = var.family
  parameters    = var.parameters
  tags          = local.tags
}

module "db_instance" {
  source                = "./modules/db-instance"
  create                = var.create_db_instance
  identifier            = var.identifier
  module_prefix         = local.module_prefix
  stage_prefix          = local.stage_prefix
  name                  = var.name
  delimiter             = var.delimiter
  engine                = var.engine
  engine_version        = var.engine_version
  instance_class        = var.instance_class
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  deletion_protection   = var.deletion_protection
  storage_encrypted     = var.storage_encrypted
  kms_key_id            = var.kms_key_id
  license_model         = var.license_model
  namespace             = var.namespace
  environment           = var.environment
  stage                 = var.stage
  db_name               = var.db_name


  username                            = var.username == "" ? module.rds_ssm_param_username.map[format("/%s/${var.name}-username", local.stage_prefix)] : var.username
  password                            = var.password == "" ? module.rds_ssm_param_secret.map[format("/%s/${var.name}-password", local.stage_prefix)] : var.password
  port                                = var.port
  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  replicate_source_db = var.replicate_source_db

  snapshot_identifier                   = var.snapshot_identifier
  vpc_security_group_ids                = coalescelist(var.vpc_security_group_ids, [aws_security_group.this[0].id])
  db_subnet_group_name                  = local.db_subnet_group_name
  parameter_group_name                  = local.parameter_group_name
  availability_zone                     = var.availability_zone
  multi_az                              = var.multi_az
  iops                                  = var.iops
  publicly_accessible                   = var.publicly_accessible
  allow_major_version_upgrade           = var.allow_major_version_upgrade
  auto_minor_version_upgrade            = var.auto_minor_version_upgrade
  apply_immediately                     = var.apply_immediately
  maintenance_window                    = var.maintenance_window
  skip_final_snapshot                   = var.skip_final_snapshot
  copy_tags_to_snapshot                 = var.copy_tags_to_snapshot
  final_snapshot_identifier             = var.final_snapshot_identifier
  enabled_cloudwatch_logs_exports       = var.enabled_cloudwatch_logs_exports
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_kms_key_id       = var.performance_insights_enabled ? coalesce(var.performance_insights_kms_key_id, var.kms_key_id) : null
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  backup_retention_period               = var.backup_retention_period
  backup_window                         = var.backup_window
  enable_iam_s3_import                  = var.enable_iam_s3_import
  monitoring_interval                   = var.monitoring_interval
  monitoring_role_arn                   = var.monitoring_role_arn
  monitoring_role_name                  = var.monitoring_role_name
  create_monitoring_role                = var.create_monitoring_role
  timezone                              = var.timezone
  character_set_name                    = var.character_set_name
  tags                                  = local.tags
  schedule                              = var.schedule
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------
output "db_instance_address" {
  description = "The address of the RDS instance"
  value       = module.db_instance.this_db_instance_address
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = module.db_instance.this_db_instance_arn
}

output "db_instance_availability_zone" {
  description = "The availability zone of the RDS instance"
  value       = module.db_instance.this_db_instance_availability_zone
}

output "db_instance_endpoint" {
  description = "The connection endpoint"
  value       = module.db_instance.this_db_instance_endpoint
}

output "db_instance_hosted_zone_id" {
  description = "The canonical hosted zone ID of the DB instance (to be used in a Route 53 Alias record)"
  value       = module.db_instance.this_db_instance_hosted_zone_id
}

output "db_instance_id" {
  description = "The RDS instance ID"
  value       = module.db_instance.this_db_instance_id
}

output "db_instance_resource_id" {
  description = "The RDS Resource ID of this instance"
  value       = module.db_instance.this_db_instance_resource_id
}

output "db_instance_status" {
  description = "The RDS instance status"
  value       = module.db_instance.this_db_instance_status
}

output "db_instance_name" {
  description = "The database name"
  value       = module.db_instance.this_db_instance_name
}

# output "db_instance_username" {
#   description = "The master username for the database"
#   value       = module.db_instance.this_db_instance_username
# }

# output "db_instance_password" {
#   description = "The database password (this password may be old, because Terraform doesn't track it after initial creation)"
#   value       = var.password
#   sensitive   = true
# }

output "db_instance_port" {
  description = "The database port"
  value       = module.db_instance.this_db_instance_port
}

output "db_subnet_group_id" {
  description = "The db subnet group name"
  value       = module.db_subnet_group.this_db_subnet_group_id
}

output "db_subnet_group_arn" {
  description = "The ARN of the db subnet group"
  value       = module.db_subnet_group.this_db_subnet_group_arn
}

output "db_parameter_group_id" {
  description = "The db parameter group id"
  value       = module.db_parameter_group.this_db_parameter_group_id
}

output "db_parameter_group_arn" {
  description = "The ARN of the db parameter group"
  value       = module.db_parameter_group.this_db_parameter_group_arn
}

output "db_security_group_name" {
  description = "The name of the db security group group"
  value       = aws_security_group.this.*.name
}

