# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

# Gateways

variable "enable_s3_endpoint" {
  description = "Should be true if you want to provision an S3 endpoint to the VPC"
  default     = true
}

variable "enable_dynamodb_endpoint" {
  description = "Should be true if you want to provision a DynamoDB endpoint to the VPC"
  default     = false
}

# Interfaces

variable "enable_codebuild_endpoint" {
  description = "Should be true if you want to provision an Codebuild endpoint to the VPC"
  default     = false
}

variable "codebuild_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for Codebuild endpoint"
  default     = []
}

variable "codebuild_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for Codebuild endpoint"
  default     = true
}

variable "enable_codecommit_endpoint" {
  description = "Should be true if you want to provision an Codecommit endpoint to the VPC"
  default     = false
}

variable "codecommit_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for Codecommit endpoint"
  default     = []
}

variable "codecommit_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for Codecommit endpoint"
  default     = true
}

variable "enable_git_codecommit_endpoint" {
  description = "Should be true if you want to provision an Git Codecommit endpoint to the VPC"
  default     = false
}

variable "git_codecommit_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for Git Codecommit endpoint"
  default     = []
}

variable "git_codecommit_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for Git Codecommit endpoint"
  default     = true
}

variable "enable_config_endpoint" {
  description = "Should be true if you want to provision an config endpoint to the VPC"
  default     = false
}

variable "config_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for config endpoint"
  default     = []
}

variable "config_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for config endpoint"
  default     = true
}

variable "enable_sqs_endpoint" {
  description = "Should be true if you want to provision an SQS endpoint to the VPC"
  default     = false
}

variable "sqs_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for SQS endpoint"
  default     = []
}

variable "sqs_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for SQS endpoint"
  default     = true
}

variable "enable_secretsmanager_endpoint" {
  description = "Should be true if you want to provision an Secrets Manager endpoint to the VPC"
  default     = false
}

variable "secretsmanager_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for Secrets Manager endpoint"
  type        = list(string)
  default     = []
}

variable "secretsmanager_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for Secrets Manager endpoint"
  type        = bool
  default     = true
}

variable "enable_ssm_endpoint" {
  description = "Should be true if you want to provision an SSM endpoint to the VPC"
  default     = false
}

variable "ssm_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for SSM endpoint"
  type        = list(string)
  default     = []
}

variable "ssm_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for SSM endpoint"
  type        = bool
  default     = true
}

variable "enable_ssmmessages_endpoint" {
  description = "Should be true if you want to provision a SSMMESSAGES endpoint to the VPC"
  default     = false
}

variable "ssmmessages_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for SSMMESSAGES endpoint"
  type        = list(string)
  default     = []
}

variable "ssmmessages_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for SSMMESSAGES endpoint"
  type        = bool
  default     = true
}

variable "enable_ec2_endpoint" {
  description = "Should be true if you want to provision an EC2 endpoint to the VPC"
  default     = false
}

variable "ec2_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for EC2 endpoint"
  type        = list(string)
  default     = []
}

variable "ec2_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for EC2 endpoint"
  type        = bool
  default     = true
}

variable "enable_ec2messages_endpoint" {
  description = "Should be true if you want to provision an EC2MESSAGES endpoint to the VPC"
  default     = false
}

variable "ec2messages_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for EC2MESSAGES endpoint"
  type        = list(string)
  default     = []
}

variable "ec2messages_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for EC2MESSAGES endpoint"
  type        = bool
  default     = true
}

variable "enable_transferserver_endpoint" {
  description = "Should be true if you want to provision a Transer Server endpoint to the VPC"
  default     = false
}

variable "transferserver_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for Transfer Server endpoint"
  type        = list(string)
  default     = []
}

variable "transferserver_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for Transfer Server endpoint"
  type        = bool
  default     = true
}

variable "enable_ecr_api_endpoint" {
  description = "Should be true if you want to provision an ecr api endpoint to the VPC"
  default     = false
}

variable "ecr_api_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for ECR API endpoint"
  type        = list(string)
  default     = []
}

variable "ecr_api_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for ECR API endpoint"
  type        = bool
  default     = true
}

variable "enable_ecr_dkr_endpoint" {
  description = "Should be true if you want to provision an ecr dkr endpoint to the VPC"
  default     = false
}

variable "ecr_dkr_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for ECR DKR endpoint"
  type        = list(string)
  default     = []
}

variable "ecr_dkr_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for ECR DKR endpoint"
  type        = bool
  default     = true
}

variable "enable_apigw_endpoint" {
  description = "Should be true if you want to provision an api gateway endpoint to the VPC"
  default     = false
}

variable "apigw_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for API GW  endpoint"
  type        = list(string)
  default     = []
}

variable "apigw_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for API GW endpoint"
  type        = bool
  default     = true
}

variable "enable_kms_endpoint" {
  description = "Should be true if you want to provision a KMS endpoint to the VPC"
  default     = true
}

variable "kms_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for KMS endpoint"
  type        = list(string)
  default     = []
}

variable "kms_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for KMS endpoint"
  type        = bool
  default     = true
}

variable "enable_ecs_endpoint" {
  description = "Should be true if you want to provision a ECS endpoint to the VPC"
  default     = false
}

variable "ecs_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for ECS endpoint"
  type        = list(string)
  default     = []
}

variable "ecs_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for ECS endpoint"
  type        = bool
  default     = true
}

variable "enable_ecs_agent_endpoint" {
  description = "Should be true if you want to provision a ECS Agent endpoint to the VPC"
  default     = false
}

variable "ecs_agent_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for ECS Agent endpoint"
  type        = list(string)
  default     = []
}

variable "ecs_agent_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for ECS Agent endpoint"
  type        = bool
  default     = true
}

variable "enable_ecs_telemetry_endpoint" {
  description = "Should be true if you want to provision a ECS Telemetry endpoint to the VPC"
  default     = false
}

variable "ecs_telemetry_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for ECS Telemetry endpoint"
  type        = list(string)
  default     = []
}

variable "ecs_telemetry_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for ECS Telemetry endpoint"
  type        = bool
  default     = true
}

variable "enable_sns_endpoint" {
  description = "Should be true if you want to provision a SNS endpoint to the VPC"
  default     = false
}

variable "sns_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for SNS endpoint"
  type        = list(string)
  default     = []
}

variable "sns_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for SNS endpoint"
  type        = bool
  default     = true
}

variable "enable_monitoring_endpoint" {
  description = "Should be true if you want to provision a CloudWatch Monitoring endpoint to the VPC"
  default     = false
}

variable "monitoring_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for CloudWatch Monitoring endpoint"
  type        = list(string)
  default     = []
}

variable "monitoring_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for CloudWatch Monitoring endpoint"
  type        = bool
  default     = true
}

variable "enable_logs_endpoint" {
  description = "Should be true if you want to provision a CloudWatch Logs endpoint to the VPC"
  default     = false
}

variable "logs_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for CloudWatch Logs endpoint"
  type        = list(string)
  default     = []
}

variable "logs_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for CloudWatch Logs endpoint"
  type        = bool
  default     = true
}

variable "enable_events_endpoint" {
  description = "Should be true if you want to provision a CloudWatch Events endpoint to the VPC"
  default     = false
}

variable "events_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for CloudWatch Events endpoint"
  type        = list(string)
  default     = []
}

variable "events_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for CloudWatch Events endpoint"
  type        = bool
  default     = true
}

variable "enable_elasticloadbalancing_endpoint" {
  description = "Should be true if you want to provision a Elastic Load Balancing endpoint to the VPC"
  default     = false
}

variable "elasticloadbalancing_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for Elastic Load Balancing endpoint"
  type        = list(string)
  default     = []
}

variable "elasticloadbalancing_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for Elastic Load Balancing endpoint"
  type        = bool
  default     = true
}

variable "enable_cloudtrail_endpoint" {
  description = "Should be true if you want to provision a CloudTrail endpoint to the VPC"
  default     = false
}

variable "cloudtrail_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for CloudTrail endpoint"
  type        = list(string)
  default     = []
}

variable "cloudtrail_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for CloudTrail endpoint"
  type        = bool
  default     = true
}

variable "enable_kinesis_streams_endpoint" {
  description = "Should be true if you want to provision a Kinesis Streams endpoint to the VPC"
  default     = false
}

variable "kinesis_streams_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for Kinesis Streams endpoint"
  type        = list(string)
  default     = []
}

variable "kinesis_streams_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for Kinesis Streams endpoint"
  type        = bool
  default     = true
}

variable "enable_kinesis_firehose_endpoint" {
  description = "Should be true if you want to provision a Kinesis Firehose endpoint to the VPC"
  default     = false
}

variable "kinesis_firehose_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for Kinesis Firehose endpoint"
  type        = list(string)
  default     = []
}

variable "kinesis_firehose_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for Kinesis Firehose endpoint"
  type        = bool
  default     = true
}

variable "enable_glue_endpoint" {
  description = "Should be true if you want to provision a Glue endpoint to the VPC"
  default     = false
}

variable "glue_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for Glue endpoint"
  type        = list(string)
  default     = []
}

variable "glue_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for Glue endpoint"
  type        = bool
  default     = true
}

variable "enable_sts_endpoint" {
  description = "Should be true if you want to provision a STS endpoint to the VPC"
  default     = false
}

variable "sts_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for STS endpoint"
  type        = list(string)
  default     = []
}

variable "sts_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for STS endpoint"
  type        = bool
  default     = true
}

variable "enable_cloudformation_endpoint" {
  description = "Should be true if you want to provision a Cloudformation endpoint to the VPC"
  default     = false
}

variable "cloudformation_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for Cloudformation endpoint"
  type        = list(string)
  default     = []
}

variable "cloudformation_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for Cloudformation endpoint"
  type        = bool
  default     = true
}

variable "enable_codepipeline_endpoint" {
  description = "Should be true if you want to provision a CodePipeline endpoint to the VPC"
  default     = false
}

variable "codepipeline_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for CodePipeline endpoint"
  type        = list(string)
  default     = []
}

variable "codepipeline_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for CodePipeline endpoint"
  type        = bool
  default     = true
}

variable "enable_servicecatalog_endpoint" {
  description = "Should be true if you want to provision a Service Catalog endpoint to the VPC"
  default     = false
}

variable "servicecatalog_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for Service Catalog endpoint"
  type        = list(string)
  default     = []
}

variable "servicecatalog_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for Service Catalog endpoint"
  type        = bool
  default     = true
}

variable "enable_storagegateway_endpoint" {
  description = "Should be true if you want to provision a Storage Gateway endpoint to the VPC"
  default     = false
}

variable "storagegateway_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for Storage Gateway endpoint"
  type        = list(string)
  default     = []
}

variable "storagegateway_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for Storage Gateway endpoint"
  type        = bool
  default     = true
}

variable "enable_transfer_endpoint" {
  description = "Should be true if you want to provision a Transfer endpoint tothe VPC"
  default     = false
}

variable "transfer_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for Transfer endpoint"
  type        = list(string)
  default     = []
}

variable "transfer_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for Transfer endpoint"
  type        = bool
  default     = false
}

# InvalidServiceName: The Vpc Endpoint Service 'aws.sagemaker..notebook' does not exist
variable "enable_sagemaker_notebook_endpoint" {
  description = "Should be true if you want to provision a Sagemaker Notebook endpoint to the VPC"
  default     = false
}

variable "sagemaker_notebook_endpoint_region" {
  description = "Region to use for Sagemaker Notebook endpoint"
  type        = string
  default     = ""
}

variable "sagemaker_notebook_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for Sagemaker Notebook endpoint"
  type        = list(string)
  default     = []
}

variable "sagemaker_notebook_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for Sagemaker Notebook endpoint"
  type        = bool
  default     = true
}

variable "enable_sagemaker_api_endpoint" {
  description = "Should be true if you want to provision a SageMaker API endpoint to the VPC"
  default     = false
}

variable "sagemaker_api_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for SageMaker API endpoint"
  type        = list(string)
  default     = []
}

variable "sagemaker_api_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for SageMaker API endpoint"
  type        = bool
  default     = true
}

variable "enable_sagemaker_runtime_endpoint" {
  description = "Should be true if you want to provision a SageMaker Runtime endpoint to the VPC"
  type        = bool
  default     = false
}

variable "sagemaker_runtime_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for SageMaker Runtime endpoint"
  type        = list(string)
  default     = []
}

variable "sagemaker_runtime_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for SageMaker Runtime endpoint"
  type        = bool
  default     = false
}

# InvalidServiceName: The Vpc Endpoint Service 'com.amazonaws.us-east-1.appstream' does not exist
variable "enable_appstream_endpoint" {
  description = "Should be true if you want to provision a AppStream endpoint to the VPC"
  default     = false
}

variable "appstream_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for AppStream endpoint"
  type        = list(string)
  default     = []
}

variable "appstream_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for AppStream endpoint"
  type        = bool
  default     = true
}

variable "enable_appmesh_envoy_management_endpoint" {
  description = "Should be true if you want to provision a AppMesh endpoint to the VPC"
  default     = false
}

variable "appmesh_envoy_management_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for AppMesh endpoint"
  type        = list(string)
  default     = []
}

variable "appmesh_envoy_management_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for AppMesh endpoint"
  type        = bool
  default     = true
}

variable "enable_athena_endpoint" {
  description = "Should be true if you want to provision a Athena endpoint to the VPC"
  default     = false
}

variable "athena_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for Athena endpoint"
  type        = list(string)
  default     = []
}

variable "athena_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for Athena endpoint"
  type        = bool
  default     = true
}

variable "enable_rekognition_endpoint" {
  description = "Should be true if you want to provision a Rekognition endpoint to the VPC"
  default     = false
}

variable "rekognition_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for Rekognition endpoint"
  type        = list(string)
  default     = []
}

variable "rekognition_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for Rekognition endpoint"
  type        = bool
  default     = false
}

variable "default_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for any endpoints not defined"
  default     = []
}

variable "enable_datasync_endpoint" {
  description = "Should be true if you want to provision a DataSync endpoint to the VPC"
  default     = false
}

variable "datasync_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for DataSync endpoint"
  type        = list(string)
  default     = []
}

variable "datasync_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for DataSync endpoint"
  type        = bool
  default     = true
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

# Default endpoint security group

resource "aws_security_group" "vpc_endpoint_default" {
  count       = length(var.default_endpoint_security_group_ids) < 1 ? 1 : 0
  name        = replace("${local.module_prefix}-endpoint-default", "-", var.delimiter)
  description = join(" ", [var.desc_prefix, "Allow all VPC traffic"])

  vpc_id = module.vpc.vpc_id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  lifecycle {
    create_before_destroy = true
  }
}

###########################
# VPC Endpoint for DataSync
###########################
data "aws_vpc_endpoint_service" "datasync" {
  count   = var.create && var.enable_datasync_endpoint ? 1 : 0
  service = "datasync"
}

resource "aws_vpc_endpoint" "datasync" {
  count = var.create && var.enable_datasync_endpoint ? 1 : 0
  tags  = local.tags

  vpc_id            = module.vpc.vpc_id
  service_name      = data.aws_vpc_endpoint_service.datasync[0].service_name
  vpc_endpoint_type = "Interface"

  security_group_ids  = coalescelist(var.datasync_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = var.datasync_endpoint_private_dns_enabled
}


# -------

locals {
  default_endpoint_security_group_ids = length(var.default_endpoint_security_group_ids) < 1 ? [aws_security_group.vpc_endpoint_default[0].id] : var.default_endpoint_security_group_ids

  # Gateways

  vpc_endpoint_s3 = var.enable_s3_endpoint ? { "s3" = {
    id          = module.vpc.vpc_endpoint_s3_id
    prefix_list = module.vpc.vpc_endpoint_s3_pl_id
  } } : {}

  vpc_endpoint_dynamodb = var.enable_dynamodb_endpoint ? { "dynamodb" = {
    id          = module.vpc.vpc_endpoint_dynamodb_id
    prefix_list = module.vpc.vpc_endpoint_dynamodb_pl_id
  } } : {}

  # Interfaces

  vpc_endpoint_codebuild = var.enable_codebuild_endpoint ? { "codebuild" = {
    id                    = module.vpc.vpc_endpoint_codebuild_id
    dns_entry             = module.vpc.vpc_endpoint_codebuild_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_codebuild_network_interface_ids
    security_group_ids    = coalescelist(var.codebuild_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_codecommit = var.enable_codecommit_endpoint ? { "codecommit" = {
    id                    = module.vpc.vpc_endpoint_codecommit_id
    dns_entry             = module.vpc.vpc_endpoint_codecommit_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_codecommit_network_interface_ids
    security_group_ids    = coalescelist(var.codecommit_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_git_codecommit = var.enable_git_codecommit_endpoint ? { "git_codecommit" = {
    id                    = module.vpc.vpc_endpoint_git_codecommit_id
    dns_entry             = module.vpc.vpc_endpoint_git_codecommit_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_git_codecommit_network_interface_ids
    security_group_ids    = coalescelist(var.git_codecommit_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_config = var.enable_config_endpoint ? { "config" = {
    id                    = module.vpc.vpc_endpoint_config_id
    dns_entry             = module.vpc.vpc_endpoint_config_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_config_network_interface_ids
    security_group_ids    = coalescelist(var.config_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_sqs = var.enable_sqs_endpoint ? { "sqs" = {
    id                    = module.vpc.vpc_endpoint_sqs_id
    dns_entry             = module.vpc.vpc_endpoint_sqs_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_sqs_network_interface_ids
    security_group_ids    = coalescelist(var.sqs_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_secretsmanager = var.enable_secretsmanager_endpoint ? { "secretsmanager" = {
    id                    = module.vpc.vpc_endpoint_secretsmanager_id
    dns_entry             = module.vpc.vpc_endpoint_secretsmanager_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_secretsmanager_network_interface_ids
    security_group_ids    = coalescelist(var.secretsmanager_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_ssm = var.enable_ssm_endpoint ? { "ssm" = {
    id                    = module.vpc.vpc_endpoint_ssm_id
    dns_entry             = module.vpc.vpc_endpoint_ssm_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_ssm_network_interface_ids
    security_group_ids    = coalescelist(var.ssm_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_ssmmessages = var.enable_ssmmessages_endpoint ? { "ssmmessages" = {
    id                    = module.vpc.vpc_endpoint_ssmmessages_id
    dns_entry             = module.vpc.vpc_endpoint_ssmmessages_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_ssmmessages_network_interface_ids
    security_group_ids    = coalescelist(var.ssmmessages_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_ec2 = var.enable_ec2_endpoint ? { "ec2" = {
    id                    = module.vpc.vpc_endpoint_ec2_id
    dns_entry             = module.vpc.vpc_endpoint_ec2_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_ec2_network_interface_ids
    security_group_ids    = coalescelist(var.ec2_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_ec2messages = var.enable_ec2messages_endpoint ? { "ec2messages" = {
    id                    = module.vpc.vpc_endpoint_ec2messages_id
    dns_entry             = module.vpc.vpc_endpoint_ec2messages_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_ec2messages_network_interface_ids
    security_group_ids    = coalescelist(var.ec2messages_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_transferserver = var.enable_transferserver_endpoint ? { "transferserver" = {
    id                    = module.vpc.vpc_endpoint_transferserver_id
    dns_entry             = module.vpc.vpc_endpoint_transferserver_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_transferserver_network_interface_ids
    security_group_ids    = coalescelist(var.transferserver_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_ecr_api = var.enable_ecr_api_endpoint ? { "ecr_api" = {
    id                    = module.vpc.vpc_endpoint_ecr_api_id
    dns_entry             = module.vpc.vpc_endpoint_ecr_api_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_ecr_api_network_interface_ids
    security_group_ids    = coalescelist(var.ecr_api_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_ecr_dkr = var.enable_ecr_dkr_endpoint ? { "ecr_dkr" = {
    id                    = module.vpc.vpc_endpoint_ecr_dkr_id
    dns_entry             = module.vpc.vpc_endpoint_ecr_dkr_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_ecr_dkr_network_interface_ids
    security_group_ids    = coalescelist(var.ecr_dkr_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_apigw = var.enable_apigw_endpoint ? { "apigw" = {
    id                    = module.vpc.vpc_endpoint_apigw_id
    dns_entry             = module.vpc.vpc_endpoint_apigw_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_apigw_network_interface_ids
    security_group_ids    = coalescelist(var.apigw_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_kms = var.enable_kms_endpoint ? { "kms" = {
    id                    = module.vpc.vpc_endpoint_kms_id
    dns_entry             = module.vpc.vpc_endpoint_kms_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_kms_network_interface_ids
    security_group_ids    = coalescelist(var.kms_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_ecs = var.enable_ecs_endpoint ? { "ecs" = {
    id                    = module.vpc.vpc_endpoint_ecs_id
    dns_entry             = module.vpc.vpc_endpoint_ecs_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_ecs_network_interface_ids
    security_group_ids    = coalescelist(var.ecs_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_ecs_agent = var.enable_ecs_agent_endpoint ? { "ecs_agent" = {
    id                    = module.vpc.vpc_endpoint_ecs_agent_id
    dns_entry             = module.vpc.vpc_endpoint_ecs_agent_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_ecs_agent_network_interface_ids
    security_group_ids    = coalescelist(var.ecs_agent_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_ecs_telemetry = var.enable_ecs_telemetry_endpoint ? { "ecs_telemetry" = {
    id                    = module.vpc.vpc_endpoint_ecs_telemetry_id
    dns_entry             = module.vpc.vpc_endpoint_ecs_telemetry_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_ecs_telemetry_network_interface_ids
    security_group_ids    = coalescelist(var.ecs_telemetry_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_sns = var.enable_sns_endpoint ? { "sns" = {
    id                    = module.vpc.vpc_endpoint_sns_id
    dns_entry             = module.vpc.vpc_endpoint_sns_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_sns_network_interface_ids
    security_group_ids    = coalescelist(var.sns_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_monitoring = var.enable_monitoring_endpoint ? { "monitoring" = {
    id                    = module.vpc.vpc_endpoint_monitoring_id
    dns_entry             = module.vpc.vpc_endpoint_monitoring_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_monitoring_network_interface_ids
    security_group_ids    = coalescelist(var.monitoring_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_logs = var.enable_logs_endpoint ? { "logs" = {
    id                    = module.vpc.vpc_endpoint_logs_id
    dns_entry             = module.vpc.vpc_endpoint_logs_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_logs_network_interface_ids
    security_group_ids    = coalescelist(var.logs_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_events = var.enable_events_endpoint ? { "events" = {
    id                    = module.vpc.vpc_endpoint_events_id
    dns_entry             = module.vpc.vpc_endpoint_events_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_events_network_interface_ids
    security_group_ids    = coalescelist(var.events_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_elasticloadbalancing = var.enable_elasticloadbalancing_endpoint ? { "elasticloadbalancing" = {
    id                    = module.vpc.vpc_endpoint_elasticloadbalancing_id
    dns_entry             = module.vpc.vpc_endpoint_elasticloadbalancing_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_elasticloadbalancing_network_interface_ids
    security_group_ids    = coalescelist(var.elasticloadbalancing_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_cloudtrail = var.enable_cloudtrail_endpoint ? { "cloudtrail" = {
    id                    = module.vpc.vpc_endpoint_cloudtrail_id
    dns_entry             = module.vpc.vpc_endpoint_cloudtrail_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_cloudtrail_network_interface_ids
    security_group_ids    = coalescelist(var.cloudtrail_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_kinesis_streams = var.enable_kinesis_streams_endpoint ? { "kinesis_streams" = {
    id                          = module.vpc.vpc_endpoint_kinesis_streams_id
    dns_entry                   = module.vpc.vpc_endpoint_kinesis_streams_dns_entry
    network_interface_ids       = module.vpc.vpc_endpoint_kinesis_streams_network_interface_ids
    endpoint_security_group_ids = coalescelist(var.kinesis_streams_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_kinesis_firehose = var.enable_kinesis_firehose_endpoint ? { "kinesis_firehose" = {
    id                    = module.vpc.vpc_endpoint_kinesis_firehose_id
    dns_entry             = module.vpc.vpc_endpoint_kinesis_firehose_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_kinesis_firehose_network_interface_ids
    security_group_ids    = coalescelist(var.kinesis_firehose_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_glue = var.enable_glue_endpoint ? { "glue" = {
    id                    = module.vpc.vpc_endpoint_glue_id
    dns_entry             = module.vpc.vpc_endpoint_glue_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_glue_network_interface_ids
    security_group_ids    = coalescelist(var.glue_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_sts = var.enable_sts_endpoint ? { "sts" = {
    id                    = module.vpc.vpc_endpoint_sts_id
    dns_entry             = module.vpc.vpc_endpoint_sts_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_sts_network_interface_ids
    security_group_ids    = coalescelist(var.sts_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_cloudformation = var.enable_cloudformation_endpoint ? { "cloudformation" = {
    id                    = module.vpc.vpc_endpoint_cloudformation_id
    dns_entry             = module.vpc.vpc_endpoint_cloudformation_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_cloudformation_network_interface_ids
    security_group_ids    = coalescelist(var.cloudformation_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_codepipeline = var.enable_codepipeline_endpoint ? { "codepipeline" = {
    id                    = module.vpc.vpc_endpoint_codepipeline_id
    dns_entry             = module.vpc.vpc_endpoint_codepipeline_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_codepipeline_network_interface_ids
    security_group_ids    = coalescelist(var.codepipeline_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_servicecatalog = var.enable_servicecatalog_endpoint ? { "servicecatalog" = {
    id                    = module.vpc.vpc_endpoint_servicecatalog_id
    dns_entry             = module.vpc.vpc_endpoint_servicecatalog_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_servicecatalog_network_interface_ids
    security_group_ids    = coalescelist(var.servicecatalog_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_storagegateway = var.enable_storagegateway_endpoint ? { "storagegateway" = {
    id                    = module.vpc.vpc_endpoint_storagegateway_id
    dns_entry             = module.vpc.vpc_endpoint_storagegateway_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_storagegateway_network_interface_ids
    security_group_ids    = coalescelist(var.storagegateway_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_transfer = var.enable_transfer_endpoint ? { "transfer" = {
    id                    = module.vpc.vpc_endpoint_transfer_id
    dns_entry             = module.vpc.vpc_endpoint_transfer_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_transfer_network_interface_ids
    security_group_ids    = coalescelist(var.transfer_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  # Error: Reference to undeclared output value
  # vpc_endpoint_sagemaker_notebook = var.enable_sagemaker_notebook_endpoint ? { "sagemaker_notebook" = {
  #   id                    = module.vpc.vpc_endpoint_sagemaker_notebook_id
  #   dns_entry             = module.vpc.vpc_endpoint_sagemaker_notebook_dns_entry
  #   network_interface_ids = module.vpc.vpc_endpoint_sagemaker_notebook_network_interface_ids
  #   security_group_ids    = coalescelist(var.sagemaker_notebook_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  # } } : {}

  vpc_endpoint_sagemaker_api = var.enable_sagemaker_api_endpoint ? { "sagemaker_api" = {
    id                    = module.vpc.vpc_endpoint_sagemaker_api_id
    dns_entry             = module.vpc.vpc_endpoint_sagemaker_api_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_sagemaker_api_network_interface_ids
    security_group_ids    = coalescelist(var.sagemaker_api_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_sagemaker_runtime = var.enable_sagemaker_runtime_endpoint ? { "sagemaker_runtime" = {
    id                    = module.vpc.vpc_endpoint_sagemaker_runtime_id
    dns_entry             = module.vpc.vpc_endpoint_sagemaker_runtime_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_sagemaker_runtime_network_interface_ids
    security_group_ids    = coalescelist(var.sagemaker_runtime_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_appstream = var.enable_appstream_endpoint ? { "appstream" = {
    id                    = module.vpc.vpc_endpoint_appstream_id
    dns_entry             = module.vpc.vpc_endpoint_appstream_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_appstream_network_interface_ids
    security_group_ids    = coalescelist(var.appstream_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_appmesh_envoy_management = var.enable_appmesh_envoy_management_endpoint ? { "appmesh_envoy_management" = {
    id                    = module.vpc.vpc_endpoint_appmesh_envoy_management_id
    dns_entry             = module.vpc.vpc_endpoint_appmesh_envoy_management_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_appmesh_envoy_management_network_interface_ids
    security_group_ids    = coalescelist(var.appmesh_envoy_management_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_athena = var.enable_athena_endpoint ? { "athena" = {
    id                    = module.vpc.vpc_endpoint_athena_id
    dns_entry             = module.vpc.vpc_endpoint_athena_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_athena_network_interface_ids
    security_group_ids    = coalescelist(var.athena_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_rekognition = var.enable_rekognition_endpoint ? { "rekognition" = {
    id                    = module.vpc.vpc_endpoint_rekognition_id
    dns_entry             = module.vpc.vpc_endpoint_rekognition_dns_entry
    network_interface_ids = module.vpc.vpc_endpoint_rekognition_network_interface_ids
    security_group_ids    = coalescelist(var.rekognition_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

  vpc_endpoint_datasync = var.enable_datasync_endpoint ? { "datasync" = {
    id                    = concat(aws_vpc_endpoint.datasync.*.id, [""])[0]
    dns_entry             = flatten(aws_vpc_endpoint.datasync.*.dns_entry)
    network_interface_ids = flatten(aws_vpc_endpoint.datasync.*.network_interface_ids)
    security_group_ids    = coalescelist(var.datasync_endpoint_security_group_ids, local.default_endpoint_security_group_ids)
  } } : {}

}

locals {
  vpc_endpoint_gateways = merge(
    local.vpc_endpoint_s3,
    local.vpc_endpoint_dynamodb,
  )
  vpc_endpoint_interfaces = merge(
    local.vpc_endpoint_codebuild,
    local.vpc_endpoint_codecommit,
    local.vpc_endpoint_git_codecommit,
    local.vpc_endpoint_config,
    local.vpc_endpoint_sqs,
    local.vpc_endpoint_secretsmanager,
    local.vpc_endpoint_ssm,
    local.vpc_endpoint_ssmmessages,
    local.vpc_endpoint_ec2,
    local.vpc_endpoint_ec2messages,
    local.vpc_endpoint_transferserver,
    local.vpc_endpoint_ecr_api,
    local.vpc_endpoint_ecr_dkr,
    local.vpc_endpoint_apigw,
    local.vpc_endpoint_kms,
    local.vpc_endpoint_ecs,
    local.vpc_endpoint_ecs_agent,
    local.vpc_endpoint_ecs_telemetry,
    local.vpc_endpoint_sns,
    local.vpc_endpoint_monitoring,
    local.vpc_endpoint_logs,
    local.vpc_endpoint_events,
    local.vpc_endpoint_elasticloadbalancing,
    local.vpc_endpoint_cloudtrail,
    local.vpc_endpoint_kinesis_streams,
    local.vpc_endpoint_kinesis_firehose,
    local.vpc_endpoint_glue,
    local.vpc_endpoint_sts,
    local.vpc_endpoint_cloudformation,
    local.vpc_endpoint_codepipeline,
    local.vpc_endpoint_servicecatalog,
    local.vpc_endpoint_storagegateway,
    local.vpc_endpoint_transfer,
    # local.vpc_endpoint_sagemaker_notebook,
    local.vpc_endpoint_sagemaker_api,
    local.vpc_endpoint_sagemaker_runtime,
    local.vpc_endpoint_appstream,
    local.vpc_endpoint_appmesh_envoy_management,
    local.vpc_endpoint_athena,
    local.vpc_endpoint_rekognition,
    local.vpc_endpoint_datasync,
  )
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

# SSM Parameters

# module "parameters_vpc_endpoints" {
#   source      = "../parameters"
#   # source      = "git::https://github.com/gravicore/terraform-gravicore-modules.git//aws/parameters?ref=0.20.0"
#   providers   = { aws = "aws" }
#   create      = var.create
#   namespace   = var.namespace
#   environment = var.environment
#   stage       = var.stage
#   tags        = local.tags

#   write_parameters = {
#     "/${local.stage_prefix}/${var.name}-endpoint-gateways" = { value = jsonencode(local.vpc_endpoint_gateways)
#     description = "Map of all enabled VPC Endpoint Gateways" }
#     "/${local.stage_prefix}/${var.name}-endpoint-interface-dns-entries" = { value = jsonencode({ for k, v in local.vpc_endpoint_interfaces : k => v.dns_entry[*] })
#     description = "Map of all enabled VPC Endpoint Interface DNS entries" }
#     "/${local.stage_prefix}/${var.name}-endpoint-interface-ids" = { value = jsonencode({ for k, v in local.vpc_endpoint_interfaces : k => v.id })
#     description = "Map of all enabled VPC Endpoint Interface IDs" }
#     "/${local.stage_prefix}/${var.name}-endpoint-interface-network-interface-ids" = { value = jsonencode({ for k, v in local.vpc_endpoint_interfaces : k => v.network_interface_ids[*] })
#     description = "Map of all enabled VPC Endpoint Interface Network Interface IDs" }
#     "/${local.stage_prefix}/${var.name}-endpoint-interface-security-group-ids" = { value = jsonencode({ for k, v in local.vpc_endpoint_interfaces : k => v.security_group_ids[*] })
#     description = "Map of all enabled VPC Endpoint Interface Security Group IDs" }
#   }
# }

# Outputs

output "vpc_endpoint_gateways" {
  description = "Map of all enabled VPC Endpoint Gateways"
  value       = local.vpc_endpoint_gateways
}

resource "aws_ssm_parameter" "vpc_endpoint_gateways" {
  count       = var.create && local.vpc_endpoint_gateways != "" ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-endpoint-gateways"
  description = format("%s %s", var.desc_prefix, "Map of all enabled VPC Endpoint Gateways")
  tags        = var.tags

  type  = "String"
  value = jsonencode(local.vpc_endpoint_gateways)
}

output "vpc_endpoint_interfaces" {
  description = "Map of all enabled VPC Endpoint Interfaces"
  value       = local.vpc_endpoint_interfaces
}

# resource "aws_ssm_parameter" "vpc_endpoint_interface_dns_entries" {
#   count       = var.create && local.vpc_endpoint_interfaces != "" ? 1 : 0
#   name        = "/${local.stage_prefix}/${var.name}-endpoint-interface-dns-entries"
#   description = format("%s %s", var.desc_prefix, "Map of all enabled VPC Endpoint Interface DNS entries")
#   tags        = var.tags

#   type = "String"
#   value = jsonencode({ for k, v in local.vpc_endpoint_interfaces : k => v.dns_entry[*] })
# }

resource "aws_ssm_parameter" "vpc_endpoint_interface_ids" {
  count       = var.create && local.vpc_endpoint_gateways != "" ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-endpoint-interface-ids"
  description = format("%s %s", var.desc_prefix, "Map of all enabled VPC Endpoint Interface IDs")
  tags        = var.tags

  type  = "String"
  value = jsonencode({ for k, v in local.vpc_endpoint_interfaces : k => v.id })
}

# resource "aws_ssm_parameter" "vpc_endpoint_interface_network_interface_ids" {
#   count       = var.create && local.vpc_endpoint_interfaces != "" ? 1 : 0
#   name        = "/${local.stage_prefix}/${var.name}-endpoint-interface-network-interface-ids"
#   description = format("%s %s", var.desc_prefix, "Map of all enabled VPC Endpoint Interface Network Interface IDs")
#   tags        = var.tags

#   type = "String"
#   value = jsonencode({ for k, v in local.vpc_endpoint_interfaces : k => v.network_interface_ids[*] })
# }

resource "aws_ssm_parameter" "vpc_endpoint_interface_security_group_ids" {
  count       = var.create && local.vpc_endpoint_gateways != "" ? 1 : 0
  name        = "/${local.stage_prefix}/${var.name}-endpoint-interface-security-group-ids"
  description = format("%s %s", var.desc_prefix, "Map of all enabled VPC Endpoint Interface Security Group IDs")
  tags        = var.tags

  type  = "String"
  value = jsonencode({ for k, v in local.vpc_endpoint_interfaces : k => v.security_group_ids[*] })
}
