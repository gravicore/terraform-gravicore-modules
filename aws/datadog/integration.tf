# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "datadog_aws_account_specific_namespace_rules" {
  description = "Enables or disables metric collection for specific AWS namespaces for this AWS account only. A list of namespaces can be found at the available namespace rules API endpoint."
  type        = map(any)
  default     = {}
}

variable "datadog_excluded_regions" {
  description = "An array of AWS regions to exclude from metrics collection."
  type        = list(string)
  default     = null
}

variable "datadog_integration_role_name" {
  description = "Then name of the AWS role for Datadog to assume"
  type        = string
  default     = "integration"
}

variable "datadog_aws_filter_tags" {
  description = "Map of EC2 tags (in the form key:value) defines a filter that Datadog use when collecting metrics from EC2. Wildcards, such as ? (for single characters) and * (for multiple characters) can also be used."
  type        = map(any)
  default     = {}
}

variable "datadog_aws_host_tags" {
  description = "Array of tags (in the form key:value) to add to all hosts and metrics reporting through this integration."
  type        = map(any)
  default     = {}
}

variable "datadog_base_permissions" {
  type        = string
  default     = null
  description = "Customize the base permissions for the Datadog IAM role. Select 'Core' to only grant Datadog permissions to a very limited set of metrics and metadata (not recommended)."
}

variable "datadog_site" {
  type        = string
  default     = null
  description = "Define your Datadog Site to send data to. For the Datadog EU site, set to datadoghq.eu"
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

variable "datadog_cloud_security_posture_management_permissions" {
  type        = string
  default     = null
  description = "Set this value to 'true' to add permissions for Datadog to monitor your AWS cloud resource configurations. You need this set to 'true' to use Cloud Security Posture Management. You will also need 'BasePermissions' set to 'Full'."
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
  account_specific_namespace_rules = var.datadog_aws_account_specific_namespace_rules
  excluded_regions                 = var.datadog_excluded_regions
  filter_tags                      = local.datadog_aws_filter_tags
  host_tags                        = local.datadog_aws_host_tags
  role_name                        = local.datadog_integration_role_name
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
# Parameters:
#   ExternalId:
#     Description: >-
#       External ID for the Datadog role (generate at
#       https://app.datadoghq.com/account/settings#integrations/amazon-web-services)
#     Type: String
#   IAMRoleName:
#     Description: Customize the name of IAM role for Datadog AWS integration
#     Type: String  
#     Default: DatadogIntegrationRole
#   BasePermissions:
#     Description: >-
#       Customize the base permissions for the Datadog IAM role.
#       Select "Core" to only grant Datadog permissions to a very limited set of metrics and metadata (not recommended).
#     Type: String
#     Default: Full
#     AllowedValues:
#       - Full
#       - Core
#   LogArchives:
#     Description: >-
#       S3 paths to store log archives for log rehydration. Separate multiple paths with comma,
#       e.g., "my-bucket,my-bucket-with-path/path".
#     Type: String
#     Default: ''
#   CloudTrails:
#     Description: >-
#       S3 buckets for the Datadog CloudTrail integration. Separate multiple buckets with commas,
#       e.g., "bucket1,bucket2". Permissions will be automatically added to the Datadog integration IAM role.
#       https://docs.datadoghq.com/integrations/amazon_cloudtrail/
#     Type: String
#     Default: ''
#   CloudSecurityPostureManagementPermissions:
#     Type: String
#     Default: false
#     AllowedValues:
#       - true
#       - false
#     Description: >-
#       Set this value to "true" to add permissions for Datadog's Cloud Security Posture Management product
#       to monitor your AWS cloud resource configurations.
#       You need this set to "true" to use Cloud Security Posture Management. You will also need "BasePermissions" set to "Full".
#   DdAWSAccountId:
#     Description: >-
#       Datadog AWS account ID allowed to assume the integration IAM role. DO NOT CHANGE!
#     Type: String
#     Default: "464622532012"
resource "aws_cloudformation_stack" "datadog_integration" {
  count = var.create ? 1 : 0
  name  = local.datadog_integration_role_name
  tags  = local.tags

  template_url = "https://datadog-cloudformation-template.s3.amazonaws.com/aws/datadog_integration_role.yaml"
  capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM", "CAPABILITY_AUTO_EXPAND"]
  parameters = {
    # Required
    ExternalId      = concat(datadog_integration_aws.datadog_integration.*.external_id, [""])[0]
    BasePermissions = var.datadog_base_permissions
    IAMRoleName     = local.datadog_integration_role_name
    # Optional
    LogArchives                               = var.datadog_log_archives
    CloudTrails                               = var.datadog_cloudtrails
    CloudSecurityPostureManagementPermissions = var.datadog_cloud_security_posture_management_permissions
    # Advanced
    # DdAWSAccountId = var.datadog_aws_account_id
    EnableTerminationProtection = var.enable_termination_protection
  }

  depends_on = [aws_cloudformation_stack.datadog_policy_macro]
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "account_id" {
  value = var.account_id
}

output "datadog_id" {
  value = concat(datadog_integration_aws.datadog_integration.*.id, [""])[0]
}

output "datadog_account_specific_namespace_rules" {
  value = concat(datadog_integration_aws.datadog_integration.*.account_specific_namespace_rules, [""])[0]
}

output "datadog_excluded_regions" {
  value = concat(datadog_integration_aws.datadog_integration.*.excluded_regions, [""])[0]
}

output "datadog_external_id" {
  sensitive = true
  value     = concat(datadog_integration_aws.datadog_integration.*.external_id, [""])[0]
}

output "datadog_filter_tags" {
  value = concat(datadog_integration_aws.datadog_integration.*.filter_tags, [""])[0]
}

output "datadog_role_name" {
  value = concat(datadog_integration_aws.datadog_integration.*.role_name, [""])[0]
}
