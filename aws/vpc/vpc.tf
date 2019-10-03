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
  type        = "string"
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

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

# Create a default key/pair for public and private instances

module "ssh_key_pair_public" {
  source    = "git::https://github.com/cloudposse/terraform-aws-key-pair.git?ref=0.4.0"
  namespace = var.namespace
  stage     = var.stage
  name      = "${var.environment}-${var.name}-public"
  tags      = local.tags

  ssh_public_key_path   = "${pathexpand("~/.ssh")}/${var.namespace}"
  generate_ssh_key      = var.create
  private_key_extension = ".pem"
  public_key_extension  = ".pub"
  chmod_command         = "chmod 600 %v"
}

module "ssh_key_pair_private" {
  source    = "./key-pair"
  namespace = var.namespace
  stage     = var.stage
  name      = "${var.environment}-${var.name}-private"
  tags      = local.tags

  ssh_public_key_path   = "${pathexpand("~/.ssh")}/${var.namespace}"
  generate_ssh_key      = var.create
  private_key_extension = ".pem"
  public_key_extension  = ".pub"
  chmod_command         = "chmod 600 %v"
}

locals {
  ssh_secret_ssm_write = [
    {
      name        = "/${local.stage_prefix}/${var.name}-private-pem"
      value       = module.ssh_key_pair_private.private_key
      type        = "SecureString"
      overwrite   = "true"
      description = join(" ", [var.desc_prefix, "Private SSH Key for EC2 Instances in Private VPC Subnet"])
    },
    {
      name        = "/${local.stage_prefix}/${var.name}-private-pub"
      value       = module.ssh_key_pair_private.public_key
      type        = "SecureString"
      overwrite   = "true"
      description = join(" ", [var.desc_prefix, "Public SSH Key for EC2 Instances in Private VPC Subnet"])
    },
  ]

  # `ssh_secret_ssm_write_count` needs to be updated if `ssh_secret_ssm_write` changes
  ssh_secret_ssm_write_count = 2
}

resource "aws_ssm_parameter" "default" {
  count           = "${var.create ? local.ssh_secret_ssm_write_count : 0}"
  name            = lookup(local.ssh_secret_ssm_write[count.index], "name")
  description     = lookup(local.ssh_secret_ssm_write[count.index], "description", lookup(local.ssh_secret_ssm_write[count.index], "name"))
  type            = lookup(local.ssh_secret_ssm_write[count.index], "type", "SecureString")
  key_id          = "${lookup(local.ssh_secret_ssm_write[count.index], "type", "SecureString") == "SecureString" && length(var.parameter_store_kms_arn) > 0 ? var.parameter_store_kms_arn : ""}"
  value           = lookup(local.ssh_secret_ssm_write[count.index], "value")
  overwrite       = lookup(local.ssh_secret_ssm_write[count.index], "overwrite", "false")
  allowed_pattern = lookup(local.ssh_secret_ssm_write[count.index], "allowed_pattern", "")
  tags            = local.tags
}

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
  source     = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc?ref=v2.17.0"
  create_vpc = var.create
  name       = local.module_prefix
  tags       = local.tags

  # azs             = local.az_names
  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
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

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

// VPC module outputs

output "vpc_subnet_ids" {
  value = concat(
    module.vpc.private_subnets,
    module.vpc.public_subnets,
    module.vpc.database_subnets,
    module.vpc.redshift_subnets,
    module.vpc.elasticache_subnets,
    module.vpc.intra_subnets
  )
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "vpc_default_security_group_id" {
  description = "The ID of the security group created by default on VPC creation"
  value       = module.vpc.default_security_group_id
}

output "vpc_default_network_acl_id" {
  description = "The ID of the default network ACL"
  value       = module.vpc.default_network_acl_id
}

output "vpc_default_route_table_id" {
  description = "The ID of the default route table"
  value       = module.vpc.default_route_table_id
}

output "vpc_instance_tenancy" {
  description = "Tenancy of instances spin up within VPC"
  value       = module.vpc.vpc_instance_tenancy
}

output "vpc_enable_dns_support" {
  description = "Whether or not the VPC has DNS support"
  value       = module.vpc.vpc_enable_dns_support
}

output "vpc_enable_dns_hostnames" {
  description = "Whether or not the VPC has DNS hostname support"
  value       = module.vpc.vpc_enable_dns_hostnames
}

output "vpc_main_route_table_id" {
  description = "The ID of the main route table associated with this VPC"
  value       = module.vpc.vpc_main_route_table_id
}

output "vpc_secondary_cidr_blocks" {
  description = "List of secondary CIDR blocks of the VPC"
  value       = module.vpc.vpc_secondary_cidr_blocks
}

output "vpc_public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "vpc_public_subnets_cidr_blocks" {
  description = "List of cidr_blocks of public subnets"
  value       = module.vpc.public_subnets_cidr_blocks
}

output "vpc_public_route_table_ids" {
  description = "List of IDs of public route tables"
  value       = module.vpc.public_route_table_ids
}

output "vpc_private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "vpc_private_subnets_cidr_blocks" {
  description = "List of cidr_blocks of private subnets"
  value       = module.vpc.private_subnets_cidr_blocks
}

output "vpc_private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = module.vpc.private_route_table_ids
}

output "vpc_internal_subnets" {
  description = "List of IDs of internal subnets"
  value       = module.vpc.intra_subnets
}

output "vpc_internal_subnets_cidr_blocks" {
  description = "List of cidr_blocks of internal subnets"
  value       = module.vpc.intra_subnets_cidr_blocks
}

output "vpc_internal_route_table_ids" {
  description = "List of IDs of internal route tables"
  value       = module.vpc.intra_route_table_ids
}

output "vpc_nat_ids" {
  description = "List of allocation ID of Elastic IPs created for AWS NAT Gateway"
  value       = module.vpc.nat_ids
}

output "vpc_nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = module.vpc.nat_public_ips
}

output "vpc_natgw_ids" {
  description = "List of NAT Gateway IDs"
  value       = module.vpc.natgw_ids
}

output "vpc_igw_id" {
  description = "The ID of the Internet Gateway"
  value       = module.vpc.igw_id
}

output "vpc_vgw_id" {
  description = "The ID of the VPN Gateway"
  value       = module.vpc.vgw_id
}
