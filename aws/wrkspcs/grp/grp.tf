# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable directory_id {
  type        = string
  default     = ""
  description = "(Required) The directory identifier for registration in WorkSpaces service"
}

variable subnet_ids {
  type        = list(string)
  default     = null
  description = "(Optional) The identifiers of the subnets where the directory resides"
}

variable ip_group_ids {
  type        = list(string)
  default     = []
  description = "(Optional) The identifiers of the IP access control groups associated with the directory"
}

variable change_compute_type {
  type        = bool
  default     = false
  description = "(Optional) Whether WorkSpaces directory users can change the compute type (bundle) for their workspace"
}

variable increase_volume_size {
  type        = bool
  default     = false
  description = "(Optional) Whether WorkSpaces directory users can increase the volume size of the drives on their workspace"
}

variable rebuild_workspace {
  type        = bool
  default     = false
  description = "(Optional) Whether WorkSpaces directory users can rebuild the operating system of a workspace to its original state"
}

variable restart_workspace {
  type        = bool
  default     = true
  description = "(Optional) Whether WorkSpaces directory users can restart their workspace"
}

variable switch_running_mode {
  type        = bool
  default     = false
  description = "(Optional) Whether WorkSpaces directory users can switch the running mode of their workspace"
}

variable device_type_android {
  type        = string
  default     = "ALLOW"
  description = "(Optional) Indicates whether users can use Android devices to access their WorkSpaces. Accepted values: ALLOW, DENY"
}

variable device_type_chromeos {
  type        = string
  default     = "ALLOW"
  description = "(Optional) Indicates whether users can use Chromebooks to access their WorkSpaces. Accepted values: ALLOW, DENY"
}

variable device_type_ios {
  type        = string
  default     = "ALLOW"
  description = "(Optional) Indicates whether users can use iOS devices to access their WorkSpaces. Accepted values: ALLOW, DENY"
}

variable device_type_linux {
  type        = string
  default     = "ALLOW"
  description = "(Optional) Indicates whether users can use Linux clients to access their WorkSpaces. Accepted values: ALLOW, DENY"
}

variable device_type_osx {
  type        = string
  default     = "ALLOW"
  description = "(Optional) Indicates whether users can use macOS clients to access their WorkSpaces. Accepted values: ALLOW, DENY"
}

variable device_type_web {
  type        = string
  default     = "ALLOW"
  description = "(Optional) Indicates whether users can access their WorkSpaces through a web browser. Accepted values: ALLOW, DENY"
}

variable device_type_windows {
  type        = string
  default     = "ALLOW"
  description = "(Optional) Indicates whether users can use Windows clients to access their WorkSpaces. Accepted values: ALLOW, DENY"
}

variable device_type_zeroclient {
  type        = string
  default     = "ALLOW"
  description = "(Optional) Indicates whether users can use zero client devices to access their WorkSpaces. Accepted values: ALLOW, DENY"
}

variable custom_security_group_id {
  type        = string
  default     = ""
  description = "(Optional) The identifier of your custom security group. Should relate to the same VPC, where workspaces reside in"
}

variable default_ou {
  type        = string
  default     = ""
  description = "(Optional) The default organizational unit (OU) for your WorkSpace directories. Should conform 'OU=<value>,DC=<value>,...,DC=<value>' pattern"
}

variable enable_internet_access {
  type        = bool
  default     = null
  description = "(Optional) Indicates whether internet access is enabled for your WorkSpaces"
}

variable enable_maintenance_mode {
  type        = bool
  default     = null
  description = "(Optional) Indicates whether maintenance mode is enabled for your WorkSpaces. For more information, see https://docs.aws.amazon.com/workspaces/latest/adminguide/workspace-maintenance.html"
}

variable user_enabled_as_local_administrator {
  type        = bool
  default     = null
  description = "(Optional) Indicates whether users are local administrators of their WorkSpaces"
}

variable "ds_directory_dns_name" {
  description = "(Required if not using existing ds) The fully qualified name for the directory, such as corp.example.com"
  default     = null
  type        = string
}

variable "ds_password" {
  description = "(Required if not using existing ds) The password for the directory administrator or connector user"
  default     = null
  type        = string
}

variable "ds_password_parameter_key" {
  description = "(Optional) SSM parameter key of stored password"
  default     = null
  type        = string
}

variable "ds_username_parameter_key" {
  description = "(Optional) SSM parameter key of stored username"
  default     = null
  type        = string
}

variable "ds_size" {
  description = "(Required if not using existing ds for SimpleAD and ADConnector) The size of the directory (Small or Large are accepted values)"
  type        = string
  default     = null
}

variable "ds_subnet_ids" {
  description = "(Optional) If blank, defaults to var.subnet_ids. The identifiers of the subnets for the directory servers (2 subnets in 2 different AZs)"
  type        = list(string)
  default     = null
}

variable "ds_connect_settings_customer_username" {
  description = "(Required if not using existing ds for ADConnector) The username corresponding to the password provided"
  type        = string
  default     = null
}

variable "ds_connect_settings_customer_dns_ips" {
  description = "(Required if not using existing ds for ADConnector) The DNS IP addresses of the domain to connect to"
  type        = list(string)
  default     = null
}

variable "ds_alias" {
  description = "(Optional) The alias for the directory (must be unique amongst all aliases in AWS). Required for enable_sso"
  type        = string
  default     = null
}

variable "ds_description" {
  description = "(Optional) A textual description for the directory"
  type        = string
  default     = null
}

variable "ds_short_name" {
  description = "(Optional) The short name of the directory, such as CORP"
  type        = string
  default     = null
}

variable "ds_enable_sso" {
  description = "(Optional) Whether to enable single-sign on for the directory. Requires alias. Defaults to false"
  default     = false
}

variable "ds_type" {
  description = "(Optional) - The directory type (SimpleAD, ADConnector or MicrosoftAD are accepted values). Defaults to SimpleAD"
  type        = string
  default     = "SimpleAD"
}

variable "ds_edition" {
  description = "(Optional) The MicrosoftAD edition (Standard or Enterprise). Defaults to Enterprise (applies to MicrosoftAD type only)"
  type        = string
  default     = null
}

variable "ip_group_rules" {
  description = "(Optional) One or more pairs specifying the IP group rule (in CIDR format) from which web requests originate"
  type        = list(map(any))
  default     = null
}

variable "root_volume_encryption_enabled_default" {
  description = "(Optional) Indicates whether the data stored on the root volume is encrypted"
  type        = bool
  default     = false
}

variable "user_volume_encryption_enabled_default" {
  description = "(Optional) Indicates whether the data stored on the user volume is encrypted"
  type        = bool
  default     = false
}

variable "volume_encryption_key_default" {
  description = "(Optional) The symmetric AWS KMS customer master key (CMK) used to encrypt data stored on your WorkSpace. Amazon WorkSpaces does not support asymmetric CMKs"
  type        = string
  default     = null
}

variable "compute_type_name_default" {
  description = "(Optional) The compute type. For more information, see Amazon WorkSpaces Bundles. Valid values are VALUE, STANDARD, PERFORMANCE, POWER, GRAPHICS, POWERPRO and GRAPHICSPRO"
  type        = string
  default     = "VALUE"
}

variable "user_volume_size_gib_default" {
  description = "(Optional) The size of the user storage"
  type        = number
  default     = 10
}

variable "root_volume_size_gib_default" {
  description = "(Optional) The size of the root volume"
  type        = number
  default     = 80
}

variable "running_mode_default" {
  description = "(Optional) The running mode. For more information, see Manage the WorkSpace Running Mode. Valid values are AUTO_STOP and ALWAYS_ON"
  type        = string
  default     = "AUTO_STOP"
}

variable "running_mode_auto_stop_timeout_in_minutes_default" {
  description = "(Optional) The running mode. For more information, see Manage the WorkSpace Running Mode. Valid values are AUTO_STOP and ALWAYS_ON"
  type        = number
  default     = 60
}

variable "email_domain_default" {
  description = "The email domain to append to the username to generate the email address"
  type        = string
  default     = ""
}

variable "ws_users" {
  description = "(Required) The user name of the user for the WorkSpace. This user name must exist in the directory for the WorkSpace"
  type        = map(any)
  default     = {}
}

variable "bundle_id_default" {
  description = "(Required) The ID of the bundle for the WorkSpace"
  type        = string
  default     = ""
}

variable "ws_directory_id" {
  description = "(Required) The ID of the directory for the WorkSpace"
  type        = string
  default     = ""
}

variable "create_ws_default_role" {
  description = "(Optional) If true create default IAM role"
  type        = bool
  default     = true
}

variable "ingress_cidrs_icmp" {
  description = "(Optional) Security Group ingress CIDRS for ICMP"
  type        = list
  default     = null
}

variable "egress_rules" {
  description = "(Optional) Security Group egress CIDRS. Protocol, From Port, To Port"
  type        = list(any)
  default     = [
      ["all", 0, 0, ["0.0.0.0/0"]],
    ]
}

variable "ingress_rules" {
  description = "(Optional) Security Group ingress CIDRS. Protocol, From Port, To Port"
  type        = list(any)
  default     = []
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

module "ds" {
  create                             = var.create && var.directory_id == "" ? true : false
  name                               = var.name
  tags                               = local.tags
  aws_region                         = var.aws_region
  terraform_module                   = var.terraform_module
  description                        = var.ds_description

  namespace                          = var.namespace
  environment                        = var.environment
  stage                              = var.stage
  repository                         = var.repository

  source                             = "git::https://github.com/gravicore/terraform-gravicore-modules.git//aws/ds?ref=GDEV-230-create-directory-service-module"
  directory_dns_name                 = var.ds_directory_dns_name
  password                           = var.ds_password
  password_parameter_key             = var.ds_password_parameter_key
  username_parameter_key             = var.ds_username_parameter_key
  size                               = var.ds_size
  subnet_ids                         = coalesce(var.ds_subnet_ids, var.subnet_ids)
  connect_settings_customer_username = var.ds_connect_settings_customer_username
  connect_settings_customer_dns_ips  = var.ds_connect_settings_customer_dns_ips
  alias                              = var.ds_alias
  short_name                         = var.ds_short_name
  enable_sso                         = var.ds_enable_sso
  type                               = var.ds_type
  edition                            = var.ds_edition
}

data "aws_directory_service_directory" "default" {
  count = var.create ? 1 : 0
  directory_id = var.directory_id != "" ? var.directory_id : module.ds.id
}

data "aws_subnet" "default" {
  count = var.create ? 1 : 0
  id    = var.subnet_ids[0]
}

resource "aws_security_group" "default" {
  count = var.create ? 1 : 0
  name  = local.module_prefix
  tags  = local.tags
  description = join(" ", [var.desc_prefix, local.module_prefix, "security group"])

  vpc_id = concat(data.aws_subnet.default.*.vpc_id, [""])[0]

}

resource "aws_security_group_rule" "ds_ingress" {
  count             = var.create ? 1 : 0
  security_group_id = concat(aws_security_group.default.*.id, [""])[0]
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  source_security_group_id       = concat(data.aws_directory_service_directory.default.*.security_group_id, [""])[0]
}

resource "aws_security_group_rule" "allow_icmp" {
  count             = var.create && var.ingress_cidrs_icmp != null ? 1 : 0
  security_group_id = concat(aws_security_group.default.*.id, [""])[0]
  type              = "ingress"
  from_port         = "-1"
  to_port           = "-1"
  protocol          = "icmp"
  cidr_blocks       = var.ingress_cidrs_icmp
}

resource "aws_security_group_rule" "allow_ingress" {
  count             = var.create ? length(var.ingress_rules) : 0
  security_group_id = concat(aws_security_group.default.*.id, [""])[0]
  type              = "ingress"
  from_port         = element(var.ingress_rules[count.index], 1)
  to_port           = element(var.ingress_rules[count.index], 2)
  protocol          = element(var.ingress_rules[count.index], 0)
  cidr_blocks       = element(var.ingress_rules[count.index], 3)
}

resource "aws_security_group_rule" "allow_egress" {
  count             = var.create ? length(var.egress_rules) : 0
  security_group_id = concat(aws_security_group.default.*.id, [""])[0]
  type              = "egress"
  from_port         = element(var.egress_rules[count.index], 1)
  to_port           = element(var.egress_rules[count.index], 2)
  protocol          = element(var.egress_rules[count.index], 0)
  cidr_blocks       = element(var.egress_rules[count.index], 3)
}

resource "aws_workspaces_ip_group" "default" {
  count       = var.create && var.ip_group_rules != null ? 1 : 0
  name        = local.module_prefix
  tags        = local.tags
  description = join(" ", [var.desc_prefix, local.module_prefix, "IP access control group"])

  dynamic "rules" {
    for_each = var.ip_group_rules
    content {
      source      = rules.value["source"]
      description = lookup(rules.value, "description", null)
    }
  }
}

resource "aws_workspaces_directory" "default" {
  count        = var.create ? 1 : 0
  tags                               = local.tags

  directory_id = var.directory_id != "" ? var.directory_id : module.ds.id
  subnet_ids   = var.subnet_ids
  ip_group_ids = concat(var.ip_group_ids, aws_workspaces_ip_group.default.*.id)

  self_service_permissions {
    change_compute_type  = var.change_compute_type
    increase_volume_size = var.increase_volume_size
    rebuild_workspace    = var.rebuild_workspace
    restart_workspace    = var.restart_workspace
    switch_running_mode  = var.switch_running_mode
  }

  workspace_access_properties {
    device_type_android    = var.device_type_android
    device_type_chromeos   = var.device_type_chromeos
    device_type_ios        = var.device_type_ios
    device_type_linux      = var.device_type_linux
    device_type_osx        = var.device_type_osx
    device_type_web        = var.device_type_web
    device_type_windows    = var.device_type_windows
    device_type_zeroclient = var.device_type_zeroclient
  }

  workspace_creation_properties {
    custom_security_group_id            = var.custom_security_group_id
    default_ou                          = var.default_ou
    enable_internet_access              = var.enable_internet_access
    enable_maintenance_mode             = var.enable_maintenance_mode
    user_enabled_as_local_administrator = var.user_enabled_as_local_administrator
  }

}

resource "aws_iam_role" "workspaces_default" {
  count       = var.create && var.create_ws_default_role ? 1 : 0
  name               = "workspaces_DefaultRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "workspaces.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "workspaces_default_service_access" {
  count       = var.create && var.create_ws_default_role ? 1 : 0
  role       = concat(aws_iam_role.workspaces_default.*.name, [""])[0]
  policy_arn = "arn:aws:iam::aws:policy/AmazonWorkSpacesServiceAccess"
}

resource "aws_iam_role_policy_attachment" "workspaces_default_self_service_access" {
  count       = var.create && var.create_ws_default_role ? 1 : 0
  role       = concat(aws_iam_role.workspaces_default.*.name, [""])[0]
  policy_arn = "arn:aws:iam::aws:policy/AmazonWorkSpacesSelfServiceAccess"
}

resource "aws_workspaces_workspace" "default" {
  for_each     = var.create ? var.ws_users : {}
  tags = merge(local.tags, { "user_email" = join("@", [each.key, lookup(each.value, "email_domain", var.email_domain_default)]) })

  directory_id = var.directory_id != "" ? var.directory_id : module.ds.id
  bundle_id    = lookup(each.value, "bundle_id", var.bundle_id_default)
  user_name    = each.key

  root_volume_encryption_enabled = lookup(each.value, "root_volume_encryption_enabled", var.root_volume_encryption_enabled_default)
  user_volume_encryption_enabled = lookup(each.value, "user_volume_encryption_enabled", var.user_volume_encryption_enabled_default)
  volume_encryption_key          = lookup(each.value, "volume_encryption_key", var.volume_encryption_key_default)

  workspace_properties {
    compute_type_name                         = lookup(each.value, "compute_type_name", var.compute_type_name_default)
    user_volume_size_gib                      = lookup(each.value, "user_volume_size_gib", var.user_volume_size_gib_default)
    root_volume_size_gib                      = lookup(each.value, "root_volume_size_gib", var.root_volume_size_gib_default)
    running_mode                              = lookup(each.value, "running_mode", var.running_mode_default)
    running_mode_auto_stop_timeout_in_minutes = lookup(each.value, "running_mode_auto_stop_timeout_in_minutes", var.running_mode_auto_stop_timeout_in_minutes_default)
  }

}
# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

# output "ws_id" {
#   description = "TThe workspaces ID"
#   value       = concat(aws_workspaces_workspace.default.*.id, [""])[0]
# }

# output "ws_ip_address" {
#   description = "The IP address of the WorkSpace"
#   value       = concat(aws_workspaces_workspace.default.*.ip_address, [""])[0]
# }

# output "ws_computer_name" {
#   description = "The name of the WorkSpace, as seen by the operating system"
#   value       = concat(aws_workspaces_workspace.default.*.computer_name, [""])[0]
# }

# output "ws_state" {
#   description = "The operational state of the WorkSpace"
#   value       = concat(aws_workspaces_workspace.default.*.state, [""])[0]
# }
