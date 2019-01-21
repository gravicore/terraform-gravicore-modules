variable "name_prefix" {}

variable "tags" {
  description = "https://aws.amazon.com/answers/account-management/aws-tagging-strategies/"

  # TECHNICAL TAGS
  # Name         = ""
  # Organization = "grv"
  # Application  = ""
  # Environment  = ""
  # Container    = ""
  # Component    = ""
  # Cluster      = ""
  # AccountID    = ""
  # Version      = ""


  # BUSINESS TAGS
  # Owner      = ""
  # CostCenter = ""
  # Customer   = ""
  # Project    = ""


  # AUTOMATION TAGS
  # LastModified    = ""
  # TerraformModule = "gravicore/terraform-backend"


  # SECURITY TAGS
  # Confidentiality = ""
  # Compliance      = ""
  # local.tags["Application"],
  # local.tags["Environment"],
  # local.tags["Container"],
  # local.tags["Component"]

  default = {
    TerraformModule = "gravicore/terraform-aws-organization"
  }
}

variable "aws_region" {
  description = "The region where resources will be deployed"
  default     = "us-east-1"
}

variable "create_default_policies" {
  default = "false"
}

variable "organization_feature_set" {
  description = "(Optional) Specify 'ALL' (default) or 'CONSOLIDATED_BILLING'."
  default     = "ALL"
}

variable "create_organization" {
  default = false
}
