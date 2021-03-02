# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "parent_domain_name" {}

variable "aws_subdomain_name" {
  default = "aws"
}

variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}

variable "vpc_public_subnets" {
  type        = list(string)
  default     = []
  description = "The public subnets of the VPC to use"
}

variable "vpc_private_subnets" {
  type        = list(string)
  default     = []
  description = "The private subnets of the VPC to use"
}

variable "vpc_internal_subnets" {
  type        = list(string)
  default     = null
  description = "The internal subnets (no NAT access) of the VPC to use"
}

variable "parameter_store_kms_arn" {
  type        = string
  default     = "alias/parameter_store_key"
  description = "The ARN of a KMS key used to encrypt and decrypt SecretString values"
}

variable "map_public_ip_on_launch" {
  description = "Should be false if you do not want to auto-assign public IP on launch"
  default     = false
}

variable "enable_nat_gateway" {
  description = "Should be true if you want to provision NAT Gateways for each of your private networks"
  default     = true
}

variable "single_nat_gateway" {
  description = "Should be true if you want to provision a single shared NAT Gateway across all of your private networks"
  default     = true
}

variable "one_nat_gateway_per_az" {
  description = "Should be true if you want only one NAT Gateway per availability zone. Requires the number of `public_subnets` created to be greater than or equal to the number of availability zones specified."
  default     = false
}

variable "enable_dns_hostnames" {
  description = "Should be true to enable DNS hostnames in the VPC"
  default     = true
}

variable "enable_dns_support" {
  description = "Should be true to enable DNS support in the VPC"
  default     = true
}

variable "enable_flow_log" {
  description = "Whether or not to enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "create_flow_log_cloudwatch_log_group" {
  description = "Whether to create CloudWatch log group for VPC Flow Logs"
  type        = bool
  default     = true
}

variable "create_flow_log_cloudwatch_iam_role" {
  description = "Whether to create IAM role for VPC Flow Logs"
  type        = bool
  default     = true
}

variable "flow_log_traffic_type" {
  description = "The type of traffic to capture. Valid values: ACCEPT, REJECT, ALL."
  type        = string
  default     = "ALL"
}

variable "flow_log_destination_type" {
  description = "Type of flow log destination. Can be s3 or cloud-watch-logs."
  type        = string
  default     = "cloud-watch-logs"
}

variable "flow_log_log_format" {
  description = "The fields to include in the flow log record, in the order in which they should appear."
  type        = string
  default     = null
}

variable "flow_log_destination_arn" {
  description = "The ARN of the CloudWatch log group or S3 bucket where VPC Flow Logs will be pushed. If this ARN is a S3 bucket the appropriate permissions need to be set on that bucket's policy. When create_flow_log_cloudwatch_log_group is set to false this argument must be provided."
  type        = string
  default     = null
}

variable "flow_log_cloudwatch_iam_role_arn" {
  description = "The ARN for the IAM role that's used to post flow logs to a CloudWatch Logs log group. When flow_log_destination_arn is set to ARN of Cloudwatch Logs, this argument needs to be provided."
  type        = string
  default     = null
}

variable "flow_log_cloudwatch_log_group_name_prefix" {
  description = "Specifies the name prefix of CloudWatch Log Group for VPC flow logs."
  type        = string
  default     = "/aws/vpc-flow-log/"
}

variable "flow_log_cloudwatch_log_group_retention_in_days" {
  description = "Specifies the number of days you want to retain log events in the specified log group for VPC flow logs."
  type        = number
  default     = null
}

variable "flow_log_cloudwatch_log_group_kms_key_id" {
  description = "The ARN of the KMS Key to use when encrypting log data for VPC flow logs."
  type        = string
  default     = null
}

data "aws_kms_key" "kms" {
  for_each = var.create ? toset(["0"]) : []
  key_id   = "alias/parameter_store_key"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

locals {
  vpc_public_subnets = var.vpc_public_subnets != null ? coalescelist(var.vpc_public_subnets, compact([
    var.az_max_count >= 1 ? cidrsubnet(var.vpc_cidr_block, 6, 0) : "",
    var.az_max_count >= 2 ? cidrsubnet(var.vpc_cidr_block, 6, 1) : "",
    var.az_max_count >= 3 ? cidrsubnet(var.vpc_cidr_block, 6, 2) : "",
  ])) : []
  vpc_private_subnets = var.vpc_private_subnets != null ? coalescelist(var.vpc_private_subnets, compact([
    var.az_max_count >= 1 ? cidrsubnet(var.vpc_cidr_block, 4, 1) : "",
    var.az_max_count >= 2 ? cidrsubnet(var.vpc_cidr_block, 4, 2) : "",
    var.az_max_count >= 3 ? cidrsubnet(var.vpc_cidr_block, 4, 3) : "",
  ])) : []
  vpc_internal_subnets = var.vpc_internal_subnets != null ? coalescelist(var.vpc_internal_subnets, compact([
    var.az_max_count >= 1 ? cidrsubnet(var.vpc_cidr_block, 2, 1) : "",
    var.az_max_count >= 2 ? cidrsubnet(var.vpc_cidr_block, 2, 2) : "",
    var.az_max_count >= 3 ? cidrsubnet(var.vpc_cidr_block, 2, 3) : "",
  ])) : []
}

module "vpc" {
  source     = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc?ref=v2.33.0"
  create_vpc = var.create
  name       = local.module_prefix
  tags       = local.tags

  azs             = local.az_names
  cidr            = var.vpc_cidr_block
  public_subnets  = var.vpc_public_subnets != null ? local.vpc_public_subnets : null
  private_subnets = var.vpc_private_subnets != null ? local.vpc_private_subnets : null
  intra_subnets   = local.vpc_internal_subnets

  map_public_ip_on_launch = var.map_public_ip_on_launch
  enable_nat_gateway      = var.enable_nat_gateway
  single_nat_gateway      = var.single_nat_gateway
  one_nat_gateway_per_az  = var.one_nat_gateway_per_az
  enable_dns_support      = var.enable_dns_support
  enable_dns_hostnames    = var.enable_dns_hostnames

  enable_flow_log                                 = var.enable_flow_log
  flow_log_traffic_type                           = var.flow_log_traffic_type
  flow_log_destination_type                       = var.flow_log_destination_type
  create_flow_log_cloudwatch_iam_role             = var.create_flow_log_cloudwatch_iam_role
  create_flow_log_cloudwatch_log_group            = var.create_flow_log_cloudwatch_log_group
  flow_log_cloudwatch_log_group_name_prefix       = var.flow_log_cloudwatch_log_group_name_prefix
  flow_log_cloudwatch_log_group_retention_in_days = var.flow_log_cloudwatch_log_group_retention_in_days
  flow_log_cloudwatch_log_group_kms_key_id        = var.flow_log_cloudwatch_log_group_kms_key_id
  flow_log_destination_arn                        = var.flow_log_destination_arn
  flow_log_cloudwatch_iam_role_arn                = var.flow_log_cloudwatch_iam_role_arn
  flow_log_log_format                             = var.flow_log_log_format

  enable_s3_endpoint       = var.enable_s3_endpoint
  enable_dynamodb_endpoint = var.enable_dynamodb_endpoint

  enable_codebuild_endpoint                = var.enable_codebuild_endpoint
  enable_codecommit_endpoint               = var.enable_codecommit_endpoint
  enable_git_codecommit_endpoint           = var.enable_git_codecommit_endpoint
  enable_config_endpoint                   = var.enable_config_endpoint
  enable_sqs_endpoint                      = var.enable_sqs_endpoint
  enable_secretsmanager_endpoint           = var.enable_secretsmanager_endpoint
  enable_ssm_endpoint                      = var.enable_ssm_endpoint
  enable_ssmmessages_endpoint              = var.enable_ssmmessages_endpoint
  enable_ec2_endpoint                      = var.enable_ec2_endpoint
  enable_ec2messages_endpoint              = var.enable_ec2messages_endpoint
  enable_transferserver_endpoint           = var.enable_transferserver_endpoint
  enable_ecr_api_endpoint                  = var.enable_ecr_api_endpoint
  enable_ecr_dkr_endpoint                  = var.enable_ecr_dkr_endpoint
  enable_apigw_endpoint                    = var.enable_apigw_endpoint
  enable_kms_endpoint                      = var.enable_kms_endpoint
  enable_ecs_endpoint                      = var.enable_ecs_endpoint
  enable_ecs_agent_endpoint                = var.enable_ecs_agent_endpoint
  enable_ecs_telemetry_endpoint            = var.enable_ecs_telemetry_endpoint
  enable_sns_endpoint                      = var.enable_sns_endpoint
  enable_monitoring_endpoint               = var.enable_monitoring_endpoint
  enable_logs_endpoint                     = var.enable_logs_endpoint
  enable_events_endpoint                   = var.enable_events_endpoint
  enable_elasticloadbalancing_endpoint     = var.enable_elasticloadbalancing_endpoint
  enable_cloudtrail_endpoint               = var.enable_cloudtrail_endpoint
  enable_kinesis_streams_endpoint          = var.enable_kinesis_streams_endpoint
  enable_kinesis_firehose_endpoint         = var.enable_kinesis_firehose_endpoint
  enable_glue_endpoint                     = var.enable_glue_endpoint
  enable_sts_endpoint                      = var.enable_sts_endpoint
  enable_cloudformation_endpoint           = var.enable_cloudformation_endpoint
  enable_codepipeline_endpoint             = var.enable_codepipeline_endpoint
  enable_servicecatalog_endpoint           = var.enable_servicecatalog_endpoint
  enable_storagegateway_endpoint           = var.enable_storagegateway_endpoint
  enable_transfer_endpoint                 = var.enable_transfer_endpoint
  enable_sagemaker_notebook_endpoint       = var.enable_sagemaker_notebook_endpoint
  enable_sagemaker_api_endpoint            = var.enable_sagemaker_api_endpoint
  enable_sagemaker_runtime_endpoint        = var.enable_sagemaker_runtime_endpoint
  enable_appstream_endpoint                = var.enable_appstream_endpoint
  enable_appmesh_envoy_management_endpoint = var.enable_appmesh_envoy_management_endpoint
  enable_athena_endpoint                   = var.enable_athena_endpoint
  enable_rekognition_endpoint              = var.enable_rekognition_endpoint

  codebuild_endpoint_security_group_ids                = coalescelist(var.codebuild_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  codecommit_endpoint_security_group_ids               = coalescelist(var.codecommit_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  git_codecommit_endpoint_security_group_ids           = coalescelist(var.git_codecommit_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  config_endpoint_security_group_ids                   = coalescelist(var.config_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  sqs_endpoint_security_group_ids                      = coalescelist(var.sqs_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  secretsmanager_endpoint_security_group_ids           = coalescelist(var.secretsmanager_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  ssm_endpoint_security_group_ids                      = coalescelist(var.ssm_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  ssmmessages_endpoint_security_group_ids              = coalescelist(var.ssmmessages_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  ec2_endpoint_security_group_ids                      = coalescelist(var.ec2_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  ec2messages_endpoint_security_group_ids              = coalescelist(var.ec2messages_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  transferserver_endpoint_security_group_ids           = coalescelist(var.transferserver_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  ecr_api_endpoint_security_group_ids                  = coalescelist(var.ecr_api_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  ecr_dkr_endpoint_security_group_ids                  = coalescelist(var.ecr_dkr_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  apigw_endpoint_security_group_ids                    = coalescelist(var.apigw_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  kms_endpoint_security_group_ids                      = coalescelist(var.kms_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  ecs_endpoint_security_group_ids                      = coalescelist(var.ecs_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  ecs_agent_endpoint_security_group_ids                = coalescelist(var.ecs_agent_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  ecs_telemetry_endpoint_security_group_ids            = coalescelist(var.ecs_telemetry_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  sns_endpoint_security_group_ids                      = coalescelist(var.sns_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  monitoring_endpoint_security_group_ids               = coalescelist(var.monitoring_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  logs_endpoint_security_group_ids                     = coalescelist(var.logs_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  events_endpoint_security_group_ids                   = coalescelist(var.events_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  elasticloadbalancing_endpoint_security_group_ids     = coalescelist(var.elasticloadbalancing_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  cloudtrail_endpoint_security_group_ids               = coalescelist(var.cloudtrail_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  kinesis_streams_endpoint_security_group_ids          = coalescelist(var.kinesis_streams_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  kinesis_firehose_endpoint_security_group_ids         = coalescelist(var.kinesis_firehose_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  glue_endpoint_security_group_ids                     = coalescelist(var.glue_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  sts_endpoint_security_group_ids                      = coalescelist(var.sts_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  cloudformation_endpoint_security_group_ids           = coalescelist(var.cloudformation_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  codepipeline_endpoint_security_group_ids             = coalescelist(var.codepipeline_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  servicecatalog_endpoint_security_group_ids           = coalescelist(var.servicecatalog_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  storagegateway_endpoint_security_group_ids           = coalescelist(var.storagegateway_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  transfer_endpoint_security_group_ids                 = coalescelist(var.transfer_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  sagemaker_notebook_endpoint_security_group_ids       = coalescelist(var.sagemaker_notebook_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  sagemaker_api_endpoint_security_group_ids            = coalescelist(var.sagemaker_api_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  sagemaker_runtime_endpoint_security_group_ids        = coalescelist(var.sagemaker_runtime_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  appstream_endpoint_security_group_ids                = coalescelist(var.appstream_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  appmesh_envoy_management_endpoint_security_group_ids = coalescelist(var.appmesh_envoy_management_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  athena_endpoint_security_group_ids                   = coalescelist(var.athena_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  rekognition_endpoint_security_group_ids              = coalescelist(var.rekognition_endpoint_security_group_ids, local.default_endpoint_security_group_ids)

  codebuild_endpoint_private_dns_enabled                = var.codebuild_endpoint_private_dns_enabled
  codecommit_endpoint_private_dns_enabled               = var.codecommit_endpoint_private_dns_enabled
  git_codecommit_endpoint_private_dns_enabled           = var.git_codecommit_endpoint_private_dns_enabled
  config_endpoint_private_dns_enabled                   = var.config_endpoint_private_dns_enabled
  sqs_endpoint_private_dns_enabled                      = var.sqs_endpoint_private_dns_enabled
  secretsmanager_endpoint_private_dns_enabled           = var.secretsmanager_endpoint_private_dns_enabled
  ssm_endpoint_private_dns_enabled                      = var.ssm_endpoint_private_dns_enabled
  ssmmessages_endpoint_private_dns_enabled              = var.ssmmessages_endpoint_private_dns_enabled
  ec2_endpoint_private_dns_enabled                      = var.ec2_endpoint_private_dns_enabled
  ec2messages_endpoint_private_dns_enabled              = var.ec2messages_endpoint_private_dns_enabled
  transferserver_endpoint_private_dns_enabled           = var.transferserver_endpoint_private_dns_enabled
  ecr_api_endpoint_private_dns_enabled                  = var.ecr_api_endpoint_private_dns_enabled
  ecr_dkr_endpoint_private_dns_enabled                  = var.ecr_dkr_endpoint_private_dns_enabled
  apigw_endpoint_private_dns_enabled                    = var.apigw_endpoint_private_dns_enabled
  kms_endpoint_private_dns_enabled                      = var.kms_endpoint_private_dns_enabled
  ecs_endpoint_private_dns_enabled                      = var.ecs_endpoint_private_dns_enabled
  ecs_agent_endpoint_private_dns_enabled                = var.ecs_agent_endpoint_private_dns_enabled
  ecs_telemetry_endpoint_private_dns_enabled            = var.ecs_telemetry_endpoint_private_dns_enabled
  sns_endpoint_private_dns_enabled                      = var.sns_endpoint_private_dns_enabled
  monitoring_endpoint_private_dns_enabled               = var.monitoring_endpoint_private_dns_enabled
  logs_endpoint_private_dns_enabled                     = var.logs_endpoint_private_dns_enabled
  events_endpoint_private_dns_enabled                   = var.events_endpoint_private_dns_enabled
  elasticloadbalancing_endpoint_private_dns_enabled     = var.elasticloadbalancing_endpoint_private_dns_enabled
  cloudtrail_endpoint_private_dns_enabled               = var.cloudtrail_endpoint_private_dns_enabled
  kinesis_streams_endpoint_private_dns_enabled          = var.kinesis_streams_endpoint_private_dns_enabled
  kinesis_firehose_endpoint_private_dns_enabled         = var.kinesis_firehose_endpoint_private_dns_enabled
  glue_endpoint_private_dns_enabled                     = var.glue_endpoint_private_dns_enabled
  sts_endpoint_private_dns_enabled                      = var.sts_endpoint_private_dns_enabled
  cloudformation_endpoint_private_dns_enabled           = var.cloudformation_endpoint_private_dns_enabled
  codepipeline_endpoint_private_dns_enabled             = var.codepipeline_endpoint_private_dns_enabled
  servicecatalog_endpoint_private_dns_enabled           = var.servicecatalog_endpoint_private_dns_enabled
  storagegateway_endpoint_private_dns_enabled           = var.storagegateway_endpoint_private_dns_enabled
  transfer_endpoint_private_dns_enabled                 = var.transfer_endpoint_private_dns_enabled
  sagemaker_notebook_endpoint_private_dns_enabled       = var.sagemaker_notebook_endpoint_private_dns_enabled
  sagemaker_api_endpoint_private_dns_enabled            = var.sagemaker_api_endpoint_private_dns_enabled
  sagemaker_runtime_endpoint_private_dns_enabled        = var.sagemaker_runtime_endpoint_private_dns_enabled
  appstream_endpoint_private_dns_enabled                = var.appstream_endpoint_private_dns_enabled
  appmesh_envoy_management_endpoint_private_dns_enabled = var.appmesh_envoy_management_endpoint_private_dns_enabled
  athena_endpoint_private_dns_enabled                   = var.athena_endpoint_private_dns_enabled
  rekognition_endpoint_private_dns_enabled              = var.rekognition_endpoint_private_dns_enabled
}

locals {
  vpc_subnet_ids = concat(
    module.vpc.private_subnets,
    module.vpc.public_subnets,
    module.vpc.database_subnets,
    module.vpc.redshift_subnets,
    module.vpc.elasticache_subnets,
    module.vpc.intra_subnets
  )
}
# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

# Outputs

output "vpc_subnet_ids" {
  description = "List of all VPC subnet IDs"
  value       = local.vpc_subnet_ids
}

resource "aws_ssm_parameter" "vpc_subnet_ids" {
  count       = var.create && local.vpc_subnet_ids != "" ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-subnet-ids"
  description = format("%s %s", var.desc_prefix, "List of all VPC subnet IDs")
  tags        = var.tags

  type  = "StringList"
  value = join(",", local.vpc_subnet_ids)
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

resource "aws_ssm_parameter" "vpc_id" {
  count       = var.create && module.vpc.vpc_id != "" ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-id"
  description = format("%s %s", var.desc_prefix, "ID of the VPC")
  tags        = var.tags

  type  = "String"
  value = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

resource "aws_ssm_parameter" "vpc_cidr_block" {
  count       = var.create && module.vpc.vpc_cidr_block != "" ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-cidr-block"
  description = format("%s %s", var.desc_prefix, "CIDR block of the VPC")
  tags        = var.tags

  type  = "String"
  value = module.vpc.vpc_cidr_block
}

output "vpc_default_security_group_id" {
  description = "ID of the security group created by default on VPC creation"
  value       = module.vpc.default_security_group_id
}

resource "aws_ssm_parameter" "vpc_default_security_group_id" {
  count       = var.create && local.az_zone_ids_available != "" ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-default-security-group-id"
  description = format("%s %s", var.desc_prefix, "ID of the security group created by default on VPC creation")
  tags        = var.tags

  type  = "String"
  value = module.vpc.default_security_group_id
}

output "vpc_default_network_acl_id" {
  description = "ID of the default network ACL"
  value       = module.vpc.default_network_acl_id
}

resource "aws_ssm_parameter" "vpc_default_network_acl_id" {
  count       = var.create && module.vpc.default_network_acl_id != "" ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-default-network-acl-id"
  description = format("%s %s", var.desc_prefix, "ID of the default network ACL")
  tags        = var.tags

  type  = "String"
  value = module.vpc.default_network_acl_id
}

output "vpc_default_route_table_id" {
  description = "ID of the default route table"
  value       = module.vpc.default_route_table_id
}

resource "aws_ssm_parameter" "vpc_default_route_table_id" {
  count       = var.create && module.vpc.default_route_table_id != "" ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-default-route-table-id"
  description = format("%s %s", var.desc_prefix, "ID of the default route table")
  tags        = var.tags

  type  = "String"
  value = module.vpc.default_route_table_id
}

output "vpc_instance_tenancy" {
  description = "Tenancy of instances spin up within VPC"
  value       = module.vpc.vpc_instance_tenancy
}

resource "aws_ssm_parameter" "vpc_instance_tenancy" {
  count       = var.create && module.vpc.vpc_instance_tenancy != "" ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-instance-tenancy"
  description = format("%s %s", var.desc_prefix, "Tenancy of instances spin up within VPC")
  tags        = var.tags

  type  = "String"
  value = module.vpc.vpc_instance_tenancy
}

output "vpc_enable_dns_support" {
  description = "Whether or not the VPC has DNS support"
  value       = module.vpc.vpc_enable_dns_support
}

resource "aws_ssm_parameter" "vpc_enable_dns_support" {
  count       = var.create && module.vpc.vpc_enable_dns_support != "" ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-enable-dns-support"
  description = format("%s %s", var.desc_prefix, "Whether or not the VPC has DNS support")
  tags        = var.tags

  type  = "String"
  value = module.vpc.vpc_enable_dns_support
}

output "vpc_enable_dns_hostnames" {
  description = "Whether or not the VPC has DNS hostname support"
  value       = module.vpc.vpc_enable_dns_hostnames
}

resource "aws_ssm_parameter" "vpc_enable_dns_hostnames" {
  count       = var.create && module.vpc.vpc_enable_dns_hostnames != "" ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-enable-dns-hostnames"
  description = format("%s %s", var.desc_prefix, "Whether or not the VPC has DNS hostname support")
  tags        = var.tags

  type  = "String"
  value = module.vpc.vpc_enable_dns_hostnames
}

output "vpc_main_route_table_id" {
  description = "ID of the main route table associated with this VPC"
  value       = module.vpc.vpc_main_route_table_id
}

resource "aws_ssm_parameter" "vpc_main_route_table_id" {
  count       = var.create && module.vpc.vpc_main_route_table_id != "" ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-main-route-table-id"
  description = format("%s %s", var.desc_prefix, "ID of the main route table associated with this VPC")
  tags        = var.tags

  type  = "String"
  value = module.vpc.vpc_main_route_table_id
}

output "vpc_secondary_cidr_blocks" {
  description = "List of secondary CIDR blocks of the VPC"
  value       = module.vpc.vpc_secondary_cidr_blocks
}

resource "aws_ssm_parameter" "vpc_secondary_cidr_blocks" {
  count       = var.create && module.vpc.vpc_secondary_cidr_blocks != [] ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-secondary-cidr-blocks"
  description = format("%s %s", var.desc_prefix, "List of secondary CIDR blocks of the VPC")
  tags        = var.tags

  type  = "StringList"
  value = join(",", module.vpc.vpc_secondary_cidr_blocks)
}

output "vpc_public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

resource "aws_ssm_parameter" "vpc_public_subnets" {
  count       = var.create && module.vpc.public_subnets != "" ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-public-subnets"
  description = format("%s %s", var.desc_prefix, "List of IDs of public subnets")
  tags        = var.tags

  type  = "StringList"
  value = join(",", module.vpc.public_subnets)
}

output "vpc_public_subnets_cidr_blocks" {
  description = "List of cidr_blocks of public subnets"
  value       = module.vpc.public_subnets_cidr_blocks
}

resource "aws_ssm_parameter" "vpc_public_subnets_cidr_blocks" {
  count       = var.create && module.vpc.public_subnets_cidr_blocks != "" ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-public-subnets-cidr-blocks"
  description = format("%s %s", var.desc_prefix, "List of cidr_blocks of public subnets")
  tags        = var.tags

  type  = "StringList"
  value = join(",", module.vpc.public_subnets_cidr_blocks)
}

output "vpc_public_route_table_ids" {
  description = "List of IDs of public route tables"
  value       = module.vpc.public_route_table_ids
}

resource "aws_ssm_parameter" "vpc_public_route_table_ids" {
  count       = var.create && module.vpc.public_route_table_ids != "" ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-public-route-table-ids"
  description = format("%s %s", var.desc_prefix, "List of IDs of public route tables")
  tags        = var.tags

  type  = "StringList"
  value = join(",", module.vpc.public_route_table_ids)
}

output "vpc_private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

resource "aws_ssm_parameter" "vpc_private_subnets" {
  count       = var.create && module.vpc.private_subnets != "" ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-private-subnets"
  description = format("%s %s", var.desc_prefix, "List of IDs of private subnets")
  tags        = var.tags

  type  = "StringList"
  value = join(",", module.vpc.private_subnets)
}

output "vpc_private_subnets_cidr_blocks" {
  description = "List of cidr_blocks of private subnets"
  value       = module.vpc.private_subnets_cidr_blocks
}

resource "aws_ssm_parameter" "vpc_private_subnets_cidr_blocks" {
  count       = var.create && module.vpc.private_subnets_cidr_blocks != "" ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-private-subnets-cidr-blocks"
  description = format("%s %s", var.desc_prefix, "List of cidr_blocks of private subnets")
  tags        = var.tags

  type  = "StringList"
  value = join(",", module.vpc.private_subnets_cidr_blocks)
}

output "vpc_private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = module.vpc.private_route_table_ids
}

resource "aws_ssm_parameter" "vpc_private_route_table_ids" {
  count       = var.create && module.vpc.private_route_table_ids != "" ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-private-route-table-ids"
  description = format("%s %s", var.desc_prefix, "List of IDs of private route tables")
  tags        = var.tags

  type  = "StringList"
  value = join(",", module.vpc.private_route_table_ids)
}

output "vpc_internal_subnets" {
  description = "List of IDs of internal subnets"
  value       = module.vpc.intra_subnets
}

resource "aws_ssm_parameter" "vpc_intra_subnets" {
  count       = var.create && module.vpc.intra_subnets != "" ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-intra-subnets"
  description = format("%s %s", var.desc_prefix, "List of IDs of internal subnets")
  tags        = var.tags

  type  = "StringList"
  value = join(",", module.vpc.intra_subnets)
}

output "vpc_internal_subnets_cidr_blocks" {
  description = "List of cidr_blocks of internal subnets"
  value       = module.vpc.intra_subnets_cidr_blocks
}

resource "aws_ssm_parameter" "vpc_intra_subnets_cidr_blocks" {
  count       = var.create && module.vpc.intra_subnets_cidr_blocks != "" ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-intra-subnets-cidr-blocks"
  description = format("%s %s", var.desc_prefix, "List of cidr_blocks of internal subnets")
  tags        = var.tags

  type  = "StringList"
  value = join(",", module.vpc.intra_subnets_cidr_blocks)
}

output "vpc_internal_route_table_ids" {
  description = "List of IDs of internal route tables"
  value       = module.vpc.intra_route_table_ids
}

resource "aws_ssm_parameter" "vpc_intra_route_table_ids" {
  count       = var.create && module.vpc.intra_route_table_ids != "" ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-intra-route-table-ids"
  description = format("%s %s", var.desc_prefix, "List of IDs of internal route tables")
  tags        = var.tags

  type  = "StringList"
  value = join(",", module.vpc.intra_route_table_ids)
}

output "vpc_nat_ids" {
  description = "List of allocation ID of Elastic IPs created for AWS NAT Gateway"
  value       = module.vpc.nat_ids
}

resource "aws_ssm_parameter" "vpc_nat_ids" {
  count       = var.create && module.vpc.nat_ids != "" ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-nat-ids"
  description = format("%s %s", var.desc_prefix, "List of allocation ID of Elastic IPs created for AWS NAT Gateway")
  tags        = var.tags

  type  = "StringList"
  value = join(",", module.vpc.nat_ids)
}

output "vpc_nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = module.vpc.nat_public_ips
}

resource "aws_ssm_parameter" "vpc_nat_public_ips" {
  count       = var.create && module.vpc.nat_public_ips != "" ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-nat-public-ips"
  description = format("%s %s", var.desc_prefix, "List of public Elastic IPs created for AWS NAT Gateway")
  tags        = var.tags

  type  = "StringList"
  value = join(",", module.vpc.nat_public_ips)
}

output "vpc_natgw_ids" {
  description = "List of NAT Gateway IDs"
  value       = module.vpc.natgw_ids
}

resource "aws_ssm_parameter" "vpc_natgw_ids" {
  count       = var.create && module.vpc.natgw_ids != "" ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-natgw-ids"
  description = format("%s %s", var.desc_prefix, "List of NAT Gateway IDs")
  tags        = var.tags

  type  = "StringList"
  value = join(",", module.vpc.natgw_ids)
}

output "vpc_igw_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.igw_id
}

resource "aws_ssm_parameter" "vpc_igw_id" {
  count       = var.create && module.vpc.igw_id != "" ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-igw-id"
  description = format("%s %s", var.desc_prefix, "ID of the Internet Gateway")
  tags        = var.tags

  type  = "String"
  value = module.vpc.igw_id
}

output "vpc_vgw_id" {
  description = "ID of the VPN Gateway"
  value       = module.vpc.vgw_id
}

resource "aws_ssm_parameter" "vpc_vgw_id" {
  count       = var.create && module.vpc.vgw_id != "" ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-vgw-id"
  description = format("%s %s", var.desc_prefix, "ID of the VPN Gateway")
  tags        = var.tags

  type  = "String"
  value = module.vpc.vgw_id
}

output "vpc_flow_log_id" {
  description = "The ID of the Flow Log resource"
  value       = module.vpc.vpc_flow_log_id
}

resource "aws_ssm_parameter" "vpc_flow_log_id" {
  count       = var.create && module.vpc.vpc_flow_log_id != "" ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-flow-log-id"
  description = format("%s %s", var.desc_prefix, "The ID of the Flow Log resource")
  tags        = var.tags

  type  = "String"
  value = module.vpc.vpc_flow_log_id
}

output "vpc_flow_log_destination_arn" {
  description = "The ARN of the destination for VPC Flow Logs"
  value       = module.vpc.vpc_flow_log_destination_arn
}

resource "aws_ssm_parameter" "vpc_flow_log_destination_arn" {
  count       = var.create && module.vpc.vpc_flow_log_destination_arn != "" ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-flow-log-destination-arn"
  description = format("%s %s", var.desc_prefix, "The ARN of the destination for VPC Flow Logs")
  tags        = var.tags

  type  = "String"
  value = module.vpc.vpc_flow_log_destination_arn
}

output "vpc_flow_log_destination_type" {
  description = "The type of the destination for VPC Flow Logs"
  value       = module.vpc.vpc_flow_log_destination_type
}

resource "aws_ssm_parameter" "vpc_flow_log_destination_type" {
  count       = var.create && module.vpc.vpc_flow_log_destination_type != "" ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-flow-log-destination-type"
  description = format("%s %s", var.desc_prefix, "The type of the destination for VPC Flow Logs")
  tags        = var.tags

  type  = "String"
  value = module.vpc.vpc_flow_log_destination_type
}

output "vpc_flow_log_cloudwatch_iam_role_arn" {
  description = "The ARN of the IAM role used when pushing logs to Cloudwatch log group"
  value       = module.vpc.vpc_flow_log_cloudwatch_iam_role_arn
}

resource "aws_ssm_parameter" "vpc_flow_log_cloudwatch_iam_role_arn" {
  count       = var.create && module.vpc.vpc_flow_log_cloudwatch_iam_role_arn != "" ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-flow-log-cloudwatch-iam-role-arn"
  description = format("%s %s", var.desc_prefix, "The ARN of the IAM role used when pushing logs to Cloudwatch log group")
  tags        = var.tags

  type  = "String"
  value = module.vpc.vpc_flow_log_cloudwatch_iam_role_arn
}
