# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "create_load_balancer" {
  type        = bool
  default     = true
  description = ""
}

variable "security_group_ids" {
  type        = list(string)
  default     = []
  description = "The IDs of the security groups from which to allow `ingress` traffic to the DB instance"
}

variable "ingress_sg_cidr" {
  description = "List of the ingress cidr's to create the security group."
  default     = []
  type        = list(string)
}

variable "database_port" {
  description = "Database port (_e.g._ `3306` for `MySQL`). Used in the DB Security Group to allow access to the DB instance from the provided `security_group_ids`"
}

variable "multi_az" {
  type        = bool
  description = "Set to true if multi AZ deployment must be supported"
  default     = false
}

variable "storage_type" {
  type        = string
  description = "One of 'standard' (magnetic), 'gp2' (general purpose SSD), or 'io1' (provisioned IOPS SSD)."
  default     = "gp2"
}

variable "storage_encrypted" {
  type        = bool
  description = "Specifies whether the DB instance is encrypted. The default is false if not specified."
  default     = false
}

variable "iops" {
  description = "The amount of provisioned IOPS. Setting this implies a storage_type of 'io1'. Default is 0 if rds storage type is not 'io1'"
  default     = "0"
}

variable "instance_class" {
  type        = string
  description = "Class of RDS instance"

  # https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.DBInstanceClass.html
}

variable "publicly_accessible" {
  type        = bool
  description = "Determines if database can be publicly available (NOT recommended)"
  default     = false
}

variable "subnet_ids" {
  description = "List of subnets for the DB"
  type        = list
}

variable "vpc_id" {
  type        = string
  description = "VPC ID the DB instance will be created in"
}

variable "auto_minor_version_upgrade" {
  type        = bool
  description = "Allow automated minor version upgrade (e.g. from Postgres 9.5.3 to Postgres 9.5.4)"
  default     = true
}

variable "allow_major_version_upgrade" {
  type        = bool
  description = "Allow major version upgrade"
  default     = false
}

variable "apply_immediately" {
  type        = bool
  description = "Specifies whether any database modifications are applied immediately, or during the next maintenance window"
  default     = false
}

variable "maintenance_window" {
  type        = string
  description = "The window to perform maintenance in. Syntax: 'ddd:hh24:mi-ddd:hh24:mi' UTC "
  default     = "Mon:03:00-Mon:04:00"
}

variable "skip_final_snapshot" {
  type        = bool
  description = "If true (default), no snapshot will be made before deleting DB"
  default     = true
}

variable "copy_tags_to_snapshot" {
  type        = bool
  description = "Copy tags from DB to a snapshot"
  default     = true
}

variable "backup_retention_period" {
  description = "Backup retention period in days. Must be > 0 to enable backups"
  default     = 0
}

variable "backup_window" {
  type        = string
  description = "When AWS can perform DB snapshots, can't overlap with maintenance window"
  default     = "22:00-03:00"
}

variable "attributes" {
  type        = list
  default     = []
  description = "Additional attributes (e.g. `1`)"
}

variable "db_parameter" {
  type        = list
  default     = []
  description = "A list of DB parameters to apply. Note that parameters may differ from a DB family to another"
}

variable "snapshot_identifier" {
  type        = string
  description = "Snapshot identifier e.g: rds:production-2015-06-26-06-05. If specified, the module create cluster from the snapshot"
  default     = ""
}

variable "final_snapshot_identifier" {
  type        = string
  description = "Final snapshot identifier e.g.: some-db-final-snapshot-2015-06-26-06-05"
  default     = "final"
}

variable "parameter_group_name" {
  type        = string
  description = "Name of the DB parameter group to associate"
  default     = ""
}

variable "kms_key_id" {
  type        = string
  description = "The ARN for the KMS encryption key. If creating an encrypted replica, set this to the destination KMS ARN"
  default     = ""
}

variable "replicate_source_db" {
  type        = list(string)
  description = "Specifies that this resource is a Replicate database, and to use this value as the source database. This correlates to the identifier of another Amazon RDS Database to replicate. Note that if you are creating a cross-region replica of an encrypted database you will also need to specify a kms_key_id. See [DB Instance Replication](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Overview.Replication.html) and [Working with PostgreSQL and MySQL Read Replicas](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ReadRepl.html) for more information on using Replication."
}

variable "monitoring_interval" {
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance. To disable collecting Enhanced Monitoring metrics, specify 0. Valid Values are 0, 1, 5, 10, 15, 30, 60."
  default     = "0"
}

variable "same_region" {
  type        = bool
  description = "Whether this replica is in the same region as the master."
  default     = true
}

variable "number_of_instances" {
  default     = 0
  description = "Number of read replicas to creat"
}

variable "enable_dns" {
  type        = bool
  description = "Create Route53 DNS entry"
  default     = false
}

variable "dns_zone_id" {
  type        = string
  description = "Route53 DNS Zone ID"
  default     = ""
}

variable "dns_zone_name" {
  type        = string
  description = "Route53 DNS Zone name"
  default     = ""
}

variable "dns_name_prefix" {
  type        = string
  description = "Route53 DNS Zone name"
  default     = ""
}

variable "type" {
  type        = string
  default     = "CNAME"
  description = "Type of DNS records to create"
}

variable "ttl" {
  type        = string
  default     = "60"
  description = "The TTL of the record to add to the DNS zone to complete certificate validation"
}

variable "iam_database_authentication_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Specifies whether or mappings of AWS Identity and Access Management (IAM) accounts to database accounts is enabled."
}

variable "max_allocated_storage" {
  type        = number
  default     = 0
  description = "(Optional) When configured, the upper limit to which Amazon RDS can automatically scale the storage of the DB instance. Configuring this will automatically ignore differences to allocated_storage. Must be greater than or equal to allocated_storage or 0 to disable Storage Autoscaling."
}

variable "deletion_protection" {
  type        = bool
  default     = true
  description = "(Optional) If the DB instance should have deletion protection enabled. The database can't be deleted when this value is set to true. The default is false."
}

variable "enabled_cloudwatch_logs_exports" {
  type        = list(string)
  default     = ["postgresql", "upgrade"]
  description = "(Optional) List of log types to enable for exporting to CloudWatch logs. If omitted, no logs will be exported. Valid values (depending on engine): agent (MSSQL), alert, audit, error, general, listener, slowquery, trace, postgresql (PostgreSQL), upgrade (PostgreSQL)."
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_db_instance" "default" {
  count                       = var.create ? var.number_of_instances : 0
  identifier                  = format("${local.module_prefix}-%01d", count.index + 1)
  port                        = var.database_port
  instance_class              = var.instance_class
  storage_encrypted           = var.storage_encrypted
  vpc_security_group_ids      = ["${aws_security_group.replica[0].id}"]
  multi_az                    = var.multi_az
  storage_type                = var.storage_type
  iops                        = var.iops
  publicly_accessible         = var.publicly_accessible
  snapshot_identifier         = var.snapshot_identifier
  allow_major_version_upgrade = var.allow_major_version_upgrade
  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  apply_immediately           = var.apply_immediately
  maintenance_window          = var.maintenance_window
  skip_final_snapshot         = var.skip_final_snapshot
  copy_tags_to_snapshot       = var.copy_tags_to_snapshot
  backup_retention_period     = var.backup_retention_period
  backup_window               = var.backup_window
  tags                        = local.tags
  kms_key_id                  = var.kms_key_id
  monitoring_interval         = var.monitoring_interval
  replicate_source_db         = var.replicate_source_db[0]

  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  max_allocated_storage               = var.max_allocated_storage
  deletion_protection                 = var.deletion_protection
  enabled_cloudwatch_logs_exports     = var.enabled_cloudwatch_logs_exports
}

resource "aws_security_group" "replica" {
  count       = var.create ? 1 : 0
  name        = "${local.module_prefix}-replica"
  description = format("%s %s", var.desc_prefix, "Allow inbound traffic to read replicas")
  vpc_id      = var.vpc_id

  tags = local.tags
}

resource "aws_security_group_rule" "allow_ingress_sg" {
  count                    = var.create ? length(var.security_group_ids) : 0
  security_group_id        = aws_security_group.replica[0].id
  type                     = "ingress"
  from_port                = var.database_port
  to_port                  = var.database_port
  protocol                 = "tcp"
  source_security_group_id = var.security_group_ids[count.index]
}

resource "aws_security_group_rule" "allow_ingress_cidr" {
  count             = var.create && length(var.ingress_sg_cidr) > 0 ? 1 : 0
  security_group_id = aws_security_group.replica[0].id
  type              = "ingress"
  from_port         = var.database_port
  to_port           = var.database_port
  protocol          = "tcp"
  cidr_blocks       = var.ingress_sg_cidr
}

resource "aws_security_group_rule" "allow_egress" {
  count             = var.create ? 1 : 0
  security_group_id = aws_security_group.replica[0].id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_route53_record" "default" {
  count   = var.create && var.enable_dns ? length(aws_db_instance.default.*.name) : 0
  zone_id = var.dns_zone_id
  name    = join(".", [var.dns_name_prefix, var.stage, var.dns_zone_name])
  type    = var.type
  ttl     = var.ttl
  records = [aws_db_instance.default[count.index].address]

  set_identifier = "read-replica-${count.index}"

  weighted_routing_policy {
    weight = 10
  }

}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "pg_replica_instance_address" {
  description = "The address of the RDS instance"
  value       = aws_db_instance.default[*].address
}

resource "aws_ssm_parameter" "pg_replica_instance_address" {
  count       = var.create ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-address"
  description = format("%s %s", var.desc_prefix, "The address of the RDS instance")

  type      = "StringList"
  value     = join(",", aws_db_instance.default[*].address)
  overwrite = true
  tags      = local.tags
}

output "pg_replica_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.default[*].arn
}

resource "aws_ssm_parameter" "pg_replica_instance_arn" {
  count       = var.create ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-arn"
  description = format("%s %s", var.desc_prefix, "The ARN of the RDS instance")

  type      = "StringList"
  value     = join(",", aws_db_instance.default[*].arn)
  overwrite = true
  tags      = local.tags
}

output "pg_replica_instance_availability_zone" {
  description = "The availability zone of the RDS instance"
  value       = aws_db_instance.default[*].availability_zone
}

output "pg_replica_instance_multi_az" {
  description = "If the RDS instance is multi AZ enabled"
  value       = aws_db_instance.default[*].multi_az
}

output "pg_replica_instance_storage_encrypted" {
  description = "Specifies whether the DB instance is encrypted"
  value       = aws_db_instance.default[*].storage_encrypted
}

output "pg_replica_instance_endpoint" {
  description = "The connection endpoint in address:port format"
  value       = aws_db_instance.default[*].endpoint
}

resource "aws_ssm_parameter" "pg_replica_instance_endpoint" {
  count       = var.create ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-endpoint"
  description = format("%s %s", var.desc_prefix, "The connection endpoint in address:port format")

  type      = "StringList"
  value     = join(",", aws_db_instance.default[*].endpoint)
  overwrite = true
  tags      = local.tags
}

output "pg_replica_instance_hosted_zone_id" {
  description = "The canonical hosted zone ID of the DB instance (to be used in a Route 53 Alias record)"
  value       = aws_db_instance.default[*].hosted_zone_id
}

resource "aws_ssm_parameter" "pg_replica_instance_hosted_zone_id" {
  count       = var.create ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-hosted-zone-id"
  description = format("%s %s", var.desc_prefix, "The canonical hosted zone ID of the DB instance (to be used in a Route 53 Alias record)")

  type      = "StringList"
  value     = join(",", aws_db_instance.default[*].hosted_zone_id)
  overwrite = true
  tags      = local.tags
}

output "pg_replica_instance_id" {
  description = "The RDS instance ID"
  value       = aws_db_instance.default[*].id
}

resource "aws_ssm_parameter" "pg_replica_instance_id" {
  count       = var.create ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-service-access-key-id"
  description = format("%s %s", var.desc_prefix, "The RDS instance ID")

  type      = "StringList"
  value     = join(",", aws_db_instance.default[*].id)
  overwrite = true
  tags      = local.tags
}

output "pg_replica_instance_status" {
  description = "The RDS instance status"
  value       = aws_db_instance.default[*].status
}

output "pg_replica_instance_port" {
  description = "The database port"
  value       = aws_db_instance.default[*].port
}

resource "aws_ssm_parameter" "pg_replica_instance_port" {
  count       = var.create ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-port"
  description = format("%s %s", var.desc_prefix, "The database port")

  type      = "StringList"
  value     = join(",", aws_db_instance.default[*].port)
  overwrite = true
  tags      = local.tags
}

output "pg_replica_security_group_name" {
  description = "The name of the db security group group"
  value       = aws_security_group.replica.*.name
}

resource "aws_ssm_parameter" "pg_replica_security_group_name" {
  count       = var.create ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-security-group-name"
  description = format("%s %s", var.desc_prefix, "The name of the db security group group")

  type      = "StringList"
  value     = join(",", aws_security_group.replica.*.name)
  overwrite = true
  tags      = local.tags
}
