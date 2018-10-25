variable policy_type_org {
  description = "The type of policy to create, currently the only allowed value is SERVICE_CONTROL_POLICY"
  default     = "SERVICE_CONTROL_POLICY"
}

variable policy_name_org {
  description = "Name of org protect policy"
  default     = "grv_policy_org"
}

# variable "common_tags" {
#   description = "Controls the shared tags"

#   # account_id          = ""
#   # organization        = "grv"
#   # application         = "acct"
#   # component           = "sys"
#   # service             = "vpc"
#   # stage               = ""
#   # container           = "shr"
#   # resource            = ""
#   # gravicore_terraform = "true"
#   default = {}
# }

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
    TerraformModule = "github.com/gravicore/terraform-backend"
  }
}
