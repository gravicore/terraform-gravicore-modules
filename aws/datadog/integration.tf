# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "datadog_integration_role_name" {
  description = "Then name of the AWS role for Datadog to assume"
  type        = string
  default     = "integration"
}

variable "datadog_aws_filter_tags" {
  description = "Map of EC2 tags (in the form key:value) defines a filter that Datadog use when collecting metrics from EC2. Wildcards, such as ? (for single characters) and * (for multiple characters) can also be used."
  type        = map
  default     = {}
}

variable "datadog_aws_host_tags" {
  description = "Array of tags (in the form key:value) to add to all hosts and metrics reporting through this integration."
  type        = map
  default     = {}
}

variable "datadog_aws_account_specific_namespace_rules" {
  description = "Enables or disables metric collection for specific AWS namespaces for this AWS account only. A list of namespaces can be found at the available namespace rules API endpoint."
  type        = map
  default     = {}
}

variable "datadog_log_archives" {
  type        = string
  default     = null
  description = "S3 paths to store log archives for log rehydration. Separate multiple paths with comma, e.g., 'my-bucket,my-bucket-with-path/path'. Permissions will be automatically added to the Datadog integration IAM role. https://docs.datadoghq.com/logs/archives/rehydrating/?tab=awss3"
}

variable "datadog_cloudtrails" {
  type        = string
  default     = null
  description = "S3 buckets for Datadog CloudTrail integration. Separate multiple buckets with comma, e.g., 'bucket1,bucket2'. Permissions will be automatically added to the Datadog integration IAM role. https://docs.datadoghq.com/integrations/amazon_cloudtrail/"
}

variable "datadog_aws_account_id" {
  type        = string
  default     = "464622532012"
  description = "Datadog AWS account ID allowed to assume the integration IAM role. DO NOT CHANGE!"
}


locals {
  datadog_integration_role_name = join("-", [local.module_prefix, "integration"])
  datadog_aws_filter_tags       = [for key, value in var.datadog_aws_filter_tags : format("%s:%s", key, value)]
  datadog_aws_host_tags = [for key, value in merge(
    local.business_tags,
    { stage             = local.technical_tags.stage
      master_account_id = local.technical_tags.master_account_id
      account_id        = local.technical_tags.account_id
      stage_prefix      = local.automation_tags.stage_prefix
      env               = local.automation_tags.stage_prefix
    },
    var.datadog_aws_host_tags
  ) : format("%s:%s", key, value)]
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

# Create a new Datadog - Amazon Web Services integration
resource "datadog_integration_aws" "datadog_integration" {
  count = var.create ? 1 : 0

  account_id                       = local.account_id
  role_name                        = local.datadog_integration_role_name
  filter_tags                      = local.datadog_aws_filter_tags
  host_tags                        = local.datadog_aws_host_tags
  account_specific_namespace_rules = var.datadog_aws_account_specific_namespace_rules
}

# A Macro used to generate policies for the integration IAM role based on user inputs
resource "aws_cloudformation_stack" "datadog_policy_macro" {
  count = var.create ? 1 : 0
  name  = join("-", [local.module_prefix, "policy-macro"])
  tags  = local.tags

  template_url = "https://datadog-cloudformation-template.s3.amazonaws.com/aws/datadog_policy_macro.yaml"
  capabilities = ["CAPABILITY_IAM", "CAPABILITY_AUTO_EXPAND"]
}

# The IAM role for Datadog integration
resource "aws_cloudformation_stack" "datadog_integration" {
  count = var.create ? 1 : 0
  name  = local.datadog_integration_role_name
  tags  = local.tags

  template_url = "https://datadog-cloudformation-template.s3.amazonaws.com/aws/datadog_integration_role.yaml"
  capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM", "CAPABILITY_AUTO_EXPAND"]
  parameters = {
    ExternalId     = concat(datadog_integration_aws.datadog_integration.*.external_id, [""])[0]
    Permissions    = "Full"
    IAMRoleName    = local.datadog_integration_role_name
    LogArchives    = var.datadog_log_archives
    CloudTrails    = var.datadog_cloudtrails
    DdAWSAccountId = var.datadog_aws_account_id
  }

  depends_on = [aws_cloudformation_stack.datadog_policy_macro]
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "account_id" {
  value = var.account_id
}

output "datadog_external_id" {
  sensitive = true
  value     = concat(datadog_integration_aws.datadog_integration.*.external_id, [""])[0]
}
