# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "tags" {
  default = {}
}

variable "namespace" {
  default = "grv"
}

variable "environment" {
  default = "shared"
}

variable "stage" {
  default = "dev"
}

variable "repository" {
  default = ""
}

variable "stage_prefix" {}

variable "create" {
  description = "Whether to create this resource or not?"
  default     = true
}

variable "identifier" {
  description = "The name of the RDS instance, if omitted, Terraform will assign a random, unique identifier"
  default     = []
}

variable "allocated_storage" {
  description = "The allocated storage in gigabytes"
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
  default     = ""
}

variable "snapshot_identifier" {
  description = "Specifies whether or not to create this database from a snapshot. This correlates to the snapshot ID you'd find in the RDS console, e.g: rds:production-2015-06-26-06-05."
  default     = ""
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
}

variable "engine_version" {
  description = "The engine version to use"
}

variable "instance_class" {
  description = "The instance type of the RDS instance"
}

variable "name" {
  description = "The DB name to create. If omitted, no database is created initially"
  default     = ""
}

variable "username" {
  description = "Username for the master DB user"
}

variable "password" {
  description = "Password for the master DB user. Note that this may show up in logs, and it will be stored in the state file"
}

variable "port" {
  description = "The port on which the DB accepts connections"
}

variable "final_snapshot_identifier" {
  description = "The name of your final DB snapshot when this DB instance is deleted."
  default     = false
}

variable "vpc_security_group_ids" {
  description = "List of VPC security groups to associate"
  default     = []
}

variable "db_subnet_group_name" {
  description = "Name of DB subnet group. DB instance will be created in the VPC associated with the DB subnet group. If unspecified, will be created in the default VPC"
  default     = ""
}

variable "parameter_group_name" {
  description = "Name of the DB parameter group to associate"
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
}

variable "schedule" {
  description = "(Optional) Which schedule from the instance scheduler to adhere to"
  default     = ""
}

locals {
  is_mssql = "${element(split("-",var.engine), 0) == "sqlserver"}"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "enhanced_monitoring" {
  count = "${var.create_monitoring_role ? 1 : 0}"

  name               = "${var.monitoring_role_name}"
  assume_role_policy = "${file("${path.module}/policy/enhancedmonitoring.json")}"
}

resource "aws_iam_role_policy_attachment" "enhanced_monitoring" {
  count = "${var.create_monitoring_role ? 1 : 0}"

  role       = "${aws_iam_role.enhanced_monitoring.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_db_instance" "this" {
  count = "${var.create && !local.is_mssql ? length(var.identifier) : 0}"

  identifier = "${var.stage_prefix}-${element(var.identifier, count.index)}"

  engine            = "${var.engine}"
  engine_version    = "${var.engine_version}"
  instance_class    = "${var.instance_class}"
  allocated_storage = "${var.allocated_storage}"
  storage_type      = "${var.storage_type}"
  storage_encrypted = "${var.storage_encrypted}"
  kms_key_id        = "${var.kms_key_id}"
  license_model     = "${var.license_model}"

  name                                = "${var.name}"
  username                            = "${var.username}"
  password                            = "${var.password}"
  port                                = "${var.port}"
  iam_database_authentication_enabled = "${var.iam_database_authentication_enabled}"

  replicate_source_db = "${var.replicate_source_db}"

  snapshot_identifier = "${var.snapshot_identifier}"

  vpc_security_group_ids = ["${var.vpc_security_group_ids}"]
  db_subnet_group_name   = "${var.db_subnet_group_name}"
  parameter_group_name   = "${var.parameter_group_name}"

  availability_zone   = "${var.availability_zone}"
  multi_az            = "${var.multi_az}"
  iops                = "${var.iops}"
  publicly_accessible = "${var.publicly_accessible}"
  monitoring_interval = "${var.monitoring_interval}"
  monitoring_role_arn = "${coalesce(var.monitoring_role_arn, join("", aws_iam_role.enhanced_monitoring.*.arn))}"

  allow_major_version_upgrade = "${var.allow_major_version_upgrade}"
  auto_minor_version_upgrade  = "${var.auto_minor_version_upgrade}"
  apply_immediately           = "${var.apply_immediately}"
  maintenance_window          = "${var.maintenance_window}"
  skip_final_snapshot         = "${var.skip_final_snapshot}"
  copy_tags_to_snapshot       = "${var.copy_tags_to_snapshot}"
  final_snapshot_identifier   = "${var.stage_prefix}-${element(var.identifier, count.index)}-${var.final_snapshot_identifier}"

  backup_retention_period = "${var.backup_retention_period}"
  backup_window           = "${var.backup_window}"

  character_set_name = "${var.character_set_name}"

  tags = "${merge(var.tags, map("Name", format("%s", element(var.identifier, count.index)), "Schedule", format("%s", var.schedule)))}"

  lifecycle {
    ignore_changes = ["tags.%", "tags.Schedule", "tags.ScheduleStatus", "tags.ScheduleTimestamp"]
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

locals {
  this_db_instance_address           = "${element(concat(aws_db_instance.this.*.address, list("")), 0)}"
  this_db_instance_arn               = "${element(concat(aws_db_instance.this.*.arn, list("")), 0)}"
  this_db_instance_availability_zone = "${element(concat(aws_db_instance.this.*.availability_zone, list("")), 0)}"
  this_db_instance_endpoint          = "${element(concat(aws_db_instance.this.*.endpoint, list("")), 0)}"
  this_db_instance_hosted_zone_id    = "${element(concat(aws_db_instance.this.*.hosted_zone_id, list("")), 0)}"
  this_db_instance_id                = "${element(concat(aws_db_instance.this.*.id, list("")), 0)}"
  this_db_instance_resource_id       = "${element(concat(aws_db_instance.this.*.resource_id, list("")), 0)}"
  this_db_instance_status            = "${element(concat(aws_db_instance.this.*.status, list("")), 0)}"
  this_db_instance_name              = "${element(concat(aws_db_instance.this.*.name, list("")), 0)}"
  this_db_instance_username          = "${element(concat(aws_db_instance.this.*.username, list("")), 0)}"
  this_db_instance_password          = "${element(concat(aws_db_instance.this.*.password, list("")), 0)}"
  this_db_instance_port              = "${element(concat(aws_db_instance.this.*.port, list("")), 0)}"
}

output "this_db_instance_address" {
  description = "The address of the RDS instance"
  value       = "${local.this_db_instance_address}"
}

output "this_db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = "${local.this_db_instance_arn}"
}

output "this_db_instance_availability_zone" {
  description = "The availability zone of the RDS instance"
  value       = "${local.this_db_instance_availability_zone}"
}

output "this_db_instance_endpoint" {
  description = "The connection endpoint"
  value       = "${local.this_db_instance_endpoint}"
}

output "this_db_instance_hosted_zone_id" {
  description = "The canonical hosted zone ID of the DB instance (to be used in a Route 53 Alias record)"
  value       = "${local.this_db_instance_hosted_zone_id}"
}

output "this_db_instance_id" {
  description = "The RDS instance ID"
  value       = "${local.this_db_instance_id}"
}

output "this_db_instance_resource_id" {
  description = "The RDS Resource ID of this instance"
  value       = "${local.this_db_instance_resource_id}"
}

output "this_db_instance_status" {
  description = "The RDS instance status"
  value       = "${local.this_db_instance_status}"
}

output "this_db_instance_name" {
  description = "The database name"
  value       = "${local.this_db_instance_name}"
}

output "this_db_instance_username" {
  description = "The master username for the database"
  value       = "${local.this_db_instance_username}"
}

output "this_db_instance_password" {
  description = "The database password (this password may be old, because Terraform doesn't track it after initial creation)"
  value       = "${local.this_db_instance_password}"
}

output "this_db_instance_port" {
  description = "The database port"
  value       = "${local.this_db_instance_port}"
}
