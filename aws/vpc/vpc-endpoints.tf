# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "enable_s3_endpoint" {
  description = "Should be true if you want to provision an S3 endpoint to the VPC"
  default     = true
}

variable "enable_dynamodb_endpoint" {
  description = "Should be true if you want to provision a DynamoDB endpoint to the VPC"
  default     = false
}

variable "enable_codebuild_endpoint" {
  description = "Should be true if you want to provision an Codebuild endpoint to the VPC"
  default     = false
}

variable "codebuild_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for Codebuild endpoint"
  default     = []
}

# variable "codebuild_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for Codebuild endpoint"
#   default     = false
# }

variable "enable_codecommit_endpoint" {
  description = "Should be true if you want to provision an Codecommit endpoint to the VPC"
  default     = false
}

variable "codecommit_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for Codecommit endpoint"
  default     = []
}

# variable "codecommit_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for Codecommit endpoint"
#   default     = false
# }

variable "enable_git_codecommit_endpoint" {
  description = "Should be true if you want to provision an Git Codecommit endpoint to the VPC"
  default     = false
}

variable "git_codecommit_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for Git Codecommit endpoint"
  default     = []
}

# variable "git_codecommit_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for Git Codecommit endpoint"
#   default     = false
# }

variable "enable_config_endpoint" {
  description = "Should be true if you want to provision an config endpoint to the VPC"
  default     = false
}

variable "config_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for config endpoint"
  default     = []
}

# variable "config_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for config endpoint"
#   default     = false
# }

variable "enable_sqs_endpoint" {
  description = "Should be true if you want to provision an SQS endpoint to the VPC"
  default     = false
}

variable "sqs_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for SQS endpoint"
  default     = []
}

# variable "sqs_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for SQS endpoint"
#   default     = false
# }

variable "enable_secretsmanager_endpoint" {
  description = "Should be true if you want to provision an Secrets Manager endpoint to the VPC"
  default     = false
}

variable "secretsmanager_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for Secrets Manager endpoint"
  type        = list(string)
  default     = []
}

# variable "secretsmanager_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for Secrets Manager endpoint"
#   type        = bool
#   default     = false
# }

variable "enable_ssm_endpoint" {
  description = "Should be true if you want to provision an SSM endpoint to the VPC"
  default     = false
}

variable "ssm_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for SSM endpoint"
  type        = list(string)
  default     = []
}

# variable "ssm_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for SSM endpoint"
#   type        = bool
#   default     = false
# }

variable "enable_ssmmessages_endpoint" {
  description = "Should be true if you want to provision a SSMMESSAGES endpoint to the VPC"
  default     = false
}

variable "ssmmessages_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for SSMMESSAGES endpoint"
  type        = list(string)
  default     = []
}

# variable "ssmmessages_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for SSMMESSAGES endpoint"
#   type        = bool
#   default     = false
# }

variable "enable_ec2_endpoint" {
  description = "Should be true if you want to provision an EC2 endpoint to the VPC"
  default     = false
}

variable "ec2_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for EC2 endpoint"
  type        = list(string)
  default     = []
}

# variable "ec2_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for EC2 endpoint"
#   type        = bool
#   default     = false
# }

variable "enable_ec2messages_endpoint" {
  description = "Should be true if you want to provision an EC2MESSAGES endpoint to the VPC"
  default     = false
}

variable "ec2messages_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for EC2MESSAGES endpoint"
  type        = list(string)
  default     = []
}

# variable "ec2messages_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for EC2MESSAGES endpoint"
#   type        = bool
#   default     = false
# }

variable "enable_transferserver_endpoint" {
  description = "Should be true if you want to provision a Transer Server endpoint to the VPC"
  default     = false
}

variable "transferserver_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for Transfer Server endpoint"
  type        = list(string)
  default     = []
}

# variable "transferserver_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for Transfer Server endpoint"
#   type        = bool
#   default     = false
# }

variable "enable_ecr_api_endpoint" {
  description = "Should be true if you want to provision an ecr api endpoint to the VPC"
  default     = false
}

variable "ecr_api_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for ECR API endpoint"
  type        = list(string)
  default     = []
}

# variable "ecr_api_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for ECR API endpoint"
#   type        = bool
#   default     = false
# }

variable "enable_ecr_dkr_endpoint" {
  description = "Should be true if you want to provision an ecr dkr endpoint to the VPC"
  default     = false
}

variable "ecr_dkr_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for ECR DKR endpoint"
  type        = list(string)
  default     = []
}

# variable "ecr_dkr_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for ECR DKR endpoint"
#   type        = bool
#   default     = false
# }

variable "enable_apigw_endpoint" {
  description = "Should be true if you want to provision an api gateway endpoint to the VPC"
  default     = false
}

variable "apigw_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for API GW  endpoint"
  type        = list(string)
  default     = []
}

# variable "apigw_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for API GW endpoint"
#   type        = bool
#   default     = false
# }

variable "enable_kms_endpoint" {
  description = "Should be true if you want to provision a KMS endpoint to the VPC"
  default     = true
}

variable "kms_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for KMS endpoint"
  type        = list(string)
  default     = []
}

# variable "kms_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for KMS endpoint"
#   type        = bool
#   default     = false
# }

variable "enable_ecs_endpoint" {
  description = "Should be true if you want to provision a ECS endpoint to the VPC"
  default     = false
}

variable "ecs_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for ECS endpoint"
  type        = list(string)
  default     = []
}

# variable "ecs_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for ECS endpoint"
#   type        = bool
#   default     = false
# }

variable "enable_ecs_agent_endpoint" {
  description = "Should be true if you want to provision a ECS Agent endpoint to the VPC"
  default     = false
}

variable "ecs_agent_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for ECS Agent endpoint"
  type        = list(string)
  default     = []
}

# variable "ecs_agent_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for ECS Agent endpoint"
#   type        = bool
#   default     = false
# }

variable "enable_ecs_telemetry_endpoint" {
  description = "Should be true if you want to provision a ECS Telemetry endpoint to the VPC"
  default     = false
}

variable "ecs_telemetry_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for ECS Telemetry endpoint"
  type        = list(string)
  default     = []
}

# variable "ecs_telemetry_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for ECS Telemetry endpoint"
#   type        = bool
#   default     = false
# }

variable "enable_sns_endpoint" {
  description = "Should be true if you want to provision a SNS endpoint to the VPC"
  default     = false
}

variable "sns_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for SNS endpoint"
  type        = list(string)
  default     = []
}

# variable "sns_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for SNS endpoint"
#   type        = bool
#   default     = false
# }

variable "enable_monitoring_endpoint" {
  description = "Should be true if you want to provision a CloudWatch Monitoring endpoint to the VPC"
  default     = false
}

variable "monitoring_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for CloudWatch Monitoring endpoint"
  type        = list(string)
  default     = []
}

# variable "monitoring_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for CloudWatch Monitoring endpoint"
#   type        = bool
#   default     = false
# }

variable "enable_logs_endpoint" {
  description = "Should be true if you want to provision a CloudWatch Logs endpoint to the VPC"
  default     = false
}

variable "logs_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for CloudWatch Logs endpoint"
  type        = list(string)
  default     = []
}

# variable "logs_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for CloudWatch Logs endpoint"
#   type        = bool
#   default     = false
# }

variable "enable_events_endpoint" {
  description = "Should be true if you want to provision a CloudWatch Events endpoint to the VPC"
  default     = false
}

variable "events_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for CloudWatch Events endpoint"
  type        = list(string)
  default     = []
}

# variable "events_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for CloudWatch Events endpoint"
#   type        = bool
#   default     = false
# }

variable "enable_elasticloadbalancing_endpoint" {
  description = "Should be true if you want to provision a Elastic Load Balancing endpoint to the VPC"
  default     = false
}

variable "elasticloadbalancing_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for Elastic Load Balancing endpoint"
  type        = list(string)
  default     = []
}

# variable "elasticloadbalancing_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for Elastic Load Balancing endpoint"
#   type        = bool
#   default     = false
# }

variable "enable_cloudtrail_endpoint" {
  description = "Should be true if you want to provision a CloudTrail endpoint to the VPC"
  default     = false
}

variable "cloudtrail_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for CloudTrail endpoint"
  type        = list(string)
  default     = []
}

# variable "cloudtrail_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for CloudTrail endpoint"
#   type        = bool
#   default     = false
# }

variable "enable_kinesis_streams_endpoint" {
  description = "Should be true if you want to provision a Kinesis Streams endpoint to the VPC"
  default     = false
}

variable "kinesis_streams_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for Kinesis Streams endpoint"
  type        = list(string)
  default     = []
}

# variable "kinesis_streams_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for Kinesis Streams endpoint"
#   type        = bool
#   default     = false
# }

variable "enable_kinesis_firehose_endpoint" {
  description = "Should be true if you want to provision a Kinesis Firehose endpoint to the VPC"
  default     = false
}

variable "kinesis_firehose_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for Kinesis Firehose endpoint"
  type        = list(string)
  default     = []
}

# variable "kinesis_firehose_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for Kinesis Firehose endpoint"
#   type        = bool
#   default     = false
# }

variable "enable_glue_endpoint" {
  description = "Should be true if you want to provision a Glue endpoint to the VPC"
  default     = false
}

variable "glue_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for Glue endpoint"
  type        = list(string)
  default     = []
}

# variable "glue_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for Glue endpoint"
#   type        = bool
#   default     = false
# }

variable "enable_sagemaker_notebook_endpoint" {
  description = "Should be true if you want to provision a Sagemaker Notebook endpoint to the VPC"
  default     = false
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

# variable "sts_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for STS endpoint"
#   type        = bool
#   default     = false
# }

variable "enable_cloudformation_endpoint" {
  description = "Should be true if you want to provision a Cloudformation endpoint to the VPC"
  default     = false
}

variable "cloudformation_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for Cloudformation endpoint"
  type        = list(string)
  default     = []
}

# variable "cloudformation_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for Cloudformation endpoint"
#   type        = bool
#   default     = false
# }

variable "enable_codepipeline_endpoint" {
  description = "Should be true if you want to provision a CodePipeline endpoint to the VPC"
  default     = false
}

variable "codepipeline_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for CodePipeline endpoint"
  type        = list(string)
  default     = []
}

# variable "codepipeline_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for CodePipeline endpoint"
#   type        = bool
#   default     = false
# }

variable "enable_appmesh_envoy_management_endpoint" {
  description = "Should be true if you want to provision a AppMesh endpoint to the VPC"
  default     = false
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

# variable "servicecatalog_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for Service Catalog endpoint"
#   type        = bool
#   default     = false
# }

variable "enable_storagegateway_endpoint" {
  description = "Should be true if you want to provision a Storage Gateway endpoint to the VPC"
  default     = false
}

variable "storagegateway_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for Storage Gateway endpoint"
  type        = list(string)
  default     = []
}

# variable "storagegateway_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for Storage Gateway endpoint"
#   type        = bool
#   default     = false
# }

variable "enable_transfer_endpoint" {
  description = "Should be true if you want to provision a Transfer endpoint tothe VPC"
  default     = false
}

variable "transfer_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for Transfer endpoint"
  type        = list(string)
  default     = []
}

# variable "transfer_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for Transfer endpoint"
#   type        = bool
#   default     = false
# }

# InvalidServiceName: The Vpc Endpoint Service 'aws.sagemaker..notebook' does not exist
# variable "sagemaker_notebook_endpoint_region" {
#   description = "Region to use for Sagemaker Notebook endpoint"
#   type        = string
#   default     = ""
# }

# variable "sagemaker_notebook_endpoint_security_group_ids" {
#   description = "The ID of one or more security groups to associate with the network interface for Sagemaker Notebook endpoint"
#   type        = list(string)
#   default     = []
# }

# # variable "sagemaker_notebook_endpoint_private_dns_enabled" {
# #   description = "Whether or not to associate a private hosted zone with the specified VPC for Sagemaker Notebook endpoint"
# #   type        = bool
# #   default     = false
# # }

variable "enable_sagemaker_api_endpoint" {
  description = "Should be true if you want to provision a SageMaker API endpoint to the VPC"
  default     = false
}

variable "sagemaker_api_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for SageMaker API endpoint"
  type        = list(string)
  default     = []
}

# variable "sagemaker_api_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for SageMaker API endpoint"
#   type        = bool
#   default     = false
# }

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

# variable "sagemaker_runtime_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for SageMaker Runtime endpoint"
#   type        = bool
#   default     = false
# }

# InvalidServiceName: The Vpc Endpoint Service 'com.amazonaws.us-east-1.appstream' does not exist
# variable "enable_appstream_endpoint" {
#   description = "Should be true if you want to provision a AppStream endpoint to the VPC"
#   default     = false
# }

# variable "appstream_endpoint_security_group_ids" {
#   description = "The ID of one or more security groups to associate with the network interface for AppStream endpoint"
#   type        = list(string)
#   default     = []
# }

# # variable "appstream_endpoint_private_dns_enabled" {
# #   description = "Whether or not to associate a private hosted zone with the specified VPC for AppStream endpoint"
# #   type        = bool
# #   default     = false
# # }

variable "appmesh_envoy_management_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for AppMesh endpoint"
  type        = list(string)
  default     = []
}

variable "appmesh_envoy_management_endpoint_private_dns_enabled" {
  description = "Whether or not to associate a private hosted zone with the specified VPC for AppMesh endpoint"
  type        = bool
  default     = false
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

# variable "athena_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for Athena endpoint"
#   type        = bool
#   default     = false
# }

variable "enable_rekognition_endpoint" {
  description = "Should be true if you want to provision a Rekognition endpoint to the VPC"
  default     = false
}

variable "rekognition_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for Rekognition endpoint"
  type        = list(string)
  default     = []
}

# variable "rekognition_endpoint_private_dns_enabled" {
#   description = "Whether or not to associate a private hosted zone with the specified VPC for Rekognition endpoint"
#   type        = bool
#   default     = false
# }

variable "default_endpoint_security_group_ids" {
  description = "The ID of one or more security groups to associate with the network interface for any endpoints not defined"
  default     = []
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

locals {
  default_endpoint_security_group_ids = length(var.default_endpoint_security_group_ids) < 1 ? [aws_security_group.vpc_endpoint_default[0].id] : var.default_endpoint_security_group_ids
}
