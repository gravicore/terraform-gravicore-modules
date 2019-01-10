terraform {
  required_version = "~> 0.11.8"

  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
}

# ----------------------------------------------------------------------------------------------------------------------
# Providers
# ----------------------------------------------------------------------------------------------------------------------

provider "aws" {
  version = "~> 1.35"
  region  = "${var.aws_region}"

  assume_role {
    role_arn = "arn:aws:iam::${var.account_id}:role/grv_deploy_svc"
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# Module Standard Variables
# ----------------------------------------------------------------------------------------------------------------------

data "aws_kms_key" "parameter_store_key" {
  key_id = "alias/parameter_store_key"
}

module "rds_ssm_param_secret" {
  source = "git::https://github.com/cloudposse/terraform-aws-ssm-parameter-store?ref=0.1.5"

  kms_arn        = "alias/parameter_store_key"
  parameter_read = ["/${local.stage_prefix}/rds-secret"]
}

locals {
  environment_prefix = "${join("-", list(var.namespace, var.environment))}"
  stage_prefix       = "${join("-", list(var.namespace, var.environment, var.stage))}"
}

locals {
  db_subnet_group_name          = "${coalesce(var.db_subnet_group_name, module.db_subnet_group.this_db_subnet_group_id)}"
  enable_create_db_subnet_group = "${var.db_subnet_group_name == "" ? var.create_db_subnet_group : 0}"

  parameter_group_name             = "${coalesce(var.parameter_group_name, module.db_parameter_group.this_db_parameter_group_id)}"
  enable_create_db_parameter_group = "${var.parameter_group_name == "" ? var.create_db_parameter_group : 0}"

  option_group_name             = "${coalesce(var.option_group_name, module.db_option_group.this_db_option_group_id)}"
  enable_create_db_option_group = "${var.option_group_name == "" && var.engine != "postgres" ? var.create_db_option_group : 0}"

  enable_domain_iam_role = "${var.domain == "" ? "" : aws_iam_role.rds_ds_access.id}"

  enable_create_security_group = "${var.vpc_id == "" ? var.create_db_security_group : 0}"
}

module "db_subnet_group" {
  source = "./modules/db_subnet_group"

  create      = "${local.enable_create_db_subnet_group}"
  name_prefix = "${local.name_prefix}"
  subnet_ids  = ["${data.terraform_remote_state.vpc.vpc_private_subnets}"]

  tags = "${local.tags}"
}

module "db_parameter_group" {
  source = "./modules/db_parameter_group"

  create      = "${local.enable_create_db_parameter_group}"
  name_prefix = "${local.name_prefix}-${var.engine}-${replace(var.major_engine_version, ".", "-")}"
  family      = "${var.family}"

  parameters = ["${var.parameters}"]

  tags = "${local.tags}"
}

module "db_option_group" {
  source = "./modules/db_option_group"

  create                   = "${local.enable_create_db_option_group}"
  name_prefix              = "${local.name_prefix}"
  option_group_description = "${var.option_group_description}"
  engine_name              = "${var.engine}"
  major_engine_version     = "${var.major_engine_version}"
  aws_region               = "${var.aws_region}"
  kms_key_id               = "${var.kms_key_id}"

  options = ["${var.options}"]

  tags = "${local.tags}"
}

module "db_instance" {
  source = "./modules/db_instance"

  create              = "${var.create_db_instance}"
  identifier          = ["${var.identifier}"]
  engine              = "${var.engine}"
  engine_version      = "${var.engine_version}"
  instance_class      = "${var.instance_class}"
  allocated_storage   = "${var.allocated_storage}"
  storage_type        = "${var.storage_type}"
  deletion_protection = "${var.deletion_protection}"
  storage_encrypted   = "${var.storage_encrypted}"
  kms_key_id          = "${data.terraform_remote_state.acct.rds_key_arn}"
  license_model       = "${var.license_model}"
  namespace           = "${var.namespace}"
  environment         = "${var.environment}"
  stage               = "${var.stage}"

  name                                = "${var.name}"
  username                            = "${var.username}"
  password                            = "${coalesce(var.password, lookup(module.rds_ssm_param_secret.map, format("/%s/rds-secret", local.stage_prefix)))}"
  port                                = "${var.port}"
  iam_database_authentication_enabled = "${var.iam_database_authentication_enabled}"

  domain               = "${join("", data.terraform_remote_state.vpc.*.ds_directory_id)}"
  domain_iam_role_name = "${aws_iam_role.rds_ds_access.id}"

  # domain_iam_role_name = "${data.terraform_remote_state.acct.rds_ds_access_id}"

  replicate_source_db         = "${var.replicate_source_db}"
  snapshot_identifier         = "${var.snapshot_identifier}"
  vpc_security_group_ids      = ["${coalescelist(var.vpc_security_group_ids, aws_security_group.this.*.id)}"]
  db_subnet_group_name        = "${local.db_subnet_group_name}"
  parameter_group_name        = "${local.parameter_group_name}"
  option_group_name           = "${local.option_group_name}"
  availability_zone           = "${var.availability_zone}"
  multi_az                    = "${var.multi_az}"
  iops                        = "${var.iops}"
  publicly_accessible         = "${var.publicly_accessible}"
  allow_major_version_upgrade = "${var.allow_major_version_upgrade}"
  auto_minor_version_upgrade  = "${var.auto_minor_version_upgrade}"
  apply_immediately           = "${var.apply_immediately}"
  maintenance_window          = "${var.maintenance_window}"
  skip_final_snapshot         = "${var.skip_final_snapshot}"
  copy_tags_to_snapshot       = "${var.copy_tags_to_snapshot}"
  final_snapshot_identifier   = "${var.final_snapshot_identifier}"
  backup_retention_period     = "${var.backup_retention_period}"
  backup_window               = "${var.backup_window}"
  monitoring_interval         = "${var.monitoring_interval}"
  monitoring_role_arn         = "${var.monitoring_role_arn}"
  monitoring_role_name        = "${var.monitoring_role_name}"
  create_monitoring_role      = "${var.create_monitoring_role}"
  timezone                    = "${var.timezone}"
  character_set_name          = "${var.character_set_name}"
  tags                        = "${local.tags}"
  schedule                    = "${var.schedule}"
}
