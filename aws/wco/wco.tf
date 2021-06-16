# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable create_new_vpc {
  type        = string
  default     = "No"
  description = "Select Yes to deploy the solution in a new VPC"
}

variable vpc_cidr {
  type        = string
  default     = null
  description = "The default VPC CIDR used to deploy the AWS Fargate container dynamically when the solution runs"
}

variable subnet_1_cidr {
  type        = string
  default     = null
  description = "One of two subnets in different AZs where the AWS Fargate container is deployed"
}

variable subnet_2_cidr {
  type        = string
  default     = null
  description = "The second of two subnets in different AZs where the AWS Fargate container is deployed"
}

variable egress_cidr {
  type        = string
  default     = null
  description = "The Cidir Block to restrict the ECS container outbound access"
}

variable existing_subnet_id_1 {
  type        = string
  default     = null
  description = "Subnet ID to launch ECS task. Leave this blank if you selected Yes for Create New VPC or enter an existing subnet ID to run ECS task"
}

variable existing_subnet_id_2 {
  type        = string
  default     = null
  description = "Subnet ID to launch ECS task. Leave this blank if you selected Yes for Create New VPC or enter an existing subnet ID to run ECS task"
}

variable existing_security_group_id {
  type        = string
  default     = null
  description = "Security group ID to launch ECS task. Leave this blank if you selected Yes for Create New VPC or enter an existing security group ID to run ECS task"
}

variable log_level {
  type        = string
  default     = "INFO"
  description = "Sets the log level for the Lambda function logs in CloudWatch"
}

variable dry_run {
  type        = string
  default     = "Yes"
  description = "Generates a change log, but does not run any changes For more information, refer to Dry run mode"
}

variable test_end_of_month {
  type        = string
  default     = "No"
  description = "Overrides date and forces the solution to run as if it is the end of the month"
}

variable value_limit {
  type        = string
  default     = "81"
  description = "The number of hours a Value instance can run in a month before being converted to ALWAYS_ON"
}

variable standard_limit {
  type        = string
  default     = "85"
  description = "The number of hours a Standard instance can run in a month before being converted to ALWAYS_ON"
}

variable performance_limit {
  type        = string
  default     = "83"
  description = "The number of hours a Performance instance can run in a month before being converted to ALWAYS_ON"
}

variable power_limit {
  type        = string
  default     = "83"
  description = "The number of hours a Power instance can run in a month before being converted to ALWAYS_ON"
}

variable power_pro_limit {
  type        = string
  default     = "217"
  description = "The number of hours a PowerPro instance can run in a month before being converted to ALWAYS_ON"
}

variable graphics_limit {
  type        = string
  default     = "80"
  description = "The number of hours a Graphics instance can run in a month before being converted to ALWAYS_ON"
}

variable graphics_pro_limit {
  type        = string
  default     = "80"
  description = "The number of hours a GraphicsPro instance can run in a month before being converted to ALWAYS_ON"
}

variable disable_rollback {
  type        = string
  default     = null
  description = "(Optional) Set to true to disable rollback of the stack if stack creation failed. Conflicts with on_failure"
}

variable on_failure {
  type        = string
  default     = null
  description = "(Optional) Action to be taken if stack creation fails. This must be one of: DO_NOTHING, ROLLBACK, or DELETE. Conflicts with disable_rollback"
}

variable notification_arns {
  type        = list
  default     = null
  description = "(Optional) A list of SNS topic ARNs to publish stack related events"
}

variable iam_role_arn {
  type        = string
  default     = null
  description = "(Optional) The ARN of an IAM role that AWS CloudFormation assumes to create the stack. If you don't specify a value, AWS CloudFormation uses the role that was previously associated with the stack. If no role is available, AWS CloudFormation uses a temporary session that is generated from your user credentials"
}

variable timeout_in_minutes {
  type        = string
  default     = null
  description = "(Optional) The amount of time that can pass before the stack status becomes CREATE_FAILED"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_cloudformation_stack" "workspace_cost_optimizer" {
  count        = var.create ? 1 : 0
  name         = local.module_prefix
  capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM", "CAPABILITY_AUTO_EXPAND"]
  tags         = local.tags

  parameters = {
    # New VPC Settings
    CreateNewVPC = var.create_new_vpc
    VpcCIDR      = var.vpc_cidr
    Subnet1CIDR  = var.subnet_1_cidr
    Subnet2CIDR  = var.subnet_2_cidr
    EgressCIDR   = var.egress_cidr
    # Existing VPC Settings
    ExistingSubnet1Id       = var.existing_subnet_id_1
    ExistingSubnet2Id       = var.existing_subnet_id_2
    ExistingSecurityGroupId = var.existing_security_group_id
    # Testing Parameters
    LogLevel       = var.log_level
    DryRun         = var.dry_run
    TestEndOfMonth = var.test_end_of_month
    # Pricing Parameters
    ValueLimit       = var.value_limit
    StandardLimit    = var.standard_limit
    PerformanceLimit = var.performance_limit
    PowerLimit       = var.power_limit
    PowerProLimit    = var.power_pro_limit
    GraphicsLimit    = var.graphics_limit
    GraphicsProLimit = var.graphics_pro_limit
  }

  template_url = "https://s3.amazonaws.com/solutions-reference/workspaces-cost-optimizer/latest/workspaces-cost-optimizer.template"

  disable_rollback   = var.disable_rollback
  on_failure         = var.on_failure
  notification_arns  = var.notification_arns
  iam_role_arn       = var.iam_role_arn
  timeout_in_minutes = var.timeout_in_minutes
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output wco_stack_outputs {
  value     = aws_cloudformation_stack.workspace_cost_optimizer[0].outputs
  sensitive = false
}
