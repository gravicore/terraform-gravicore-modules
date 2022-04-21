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
  default     = ""
  description = "(Optional) Indicates whether users can use Android devices to access their WorkSpaces. Accepted values: ALLOW, DENY"
}

variable device_type_chromeos {
  type        = string
  default     = ""
  description = "(Optional) Indicates whether users can use Chromebooks to access their WorkSpaces. Accepted values: ALLOW, DENY"
}

variable device_type_ios {
  type        = string
  default     = ""
  description = "(Optional) Indicates whether users can use iOS devices to access their WorkSpaces. Accepted values: ALLOW, DENY"
}

variable device_type_linux {
  type        = string
  default     = ""
  description = "(Optional) Indicates whether users can use Linux clients to access their WorkSpaces. Accepted values: ALLOW, DENY"
}

variable device_type_osx {
  type        = string
  default     = ""
  description = "(Optional) Indicates whether users can use macOS clients to access their WorkSpaces. Accepted values: ALLOW, DENY"
}

variable device_type_web {
  type        = string
  default     = ""
  description = "(Optional) Indicates whether users can access their WorkSpaces through a web browser. Accepted values: ALLOW, DENY"
}

variable device_type_windows {
  type        = string
  default     = ""
  description = "(Optional) Indicates whether users can use Windows clients to access their WorkSpaces. Accepted values: ALLOW, DENY"
}

variable device_type_zeroclient {
  type        = string
  default     = ""
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
  description = "(Required) The fully qualified name for the directory, such as corp.example.com"
  default     = null
  type        = string
}

variable "ds_password" {
  description = "(Required) The password for the directory administrator or connector user"
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
  description = "(Required for SimpleAD and ADConnector) The size of the directory (Small or Large are accepted values)"
  type        = string
  default     = null
}

variable "ds_subnet_ids" {
  description = "(Required) The identifiers of the subnets for the directory servers (2 subnets in 2 different AZs)"
  type        = list(string)
}

variable "ds_connect_settings_customer_username" {
  description = "(Required for ADConnector) The username corresponding to the password provided"
  type        = string
  default     = null
}

variable "ds_connect_settings_customer_dns_ips" {
  description = "(Required for ADConnector) The DNS IP addresses of the domain to connect to"
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
  type        = list(map)
  default     = null
}

variable "ws_root_volume_encryption_enabled" {
  description = "(Optional) Indicates whether the data stored on the root volume is encrypted"
  type        = bool
  default     = false
}

variable "ws_user_volume_encryption_enabled" {
  description = "(Optional) Indicates whether the data stored on the user volume is encrypted"
  type        = bool
  default     = false
}

variable "ws_volume_encryption_key" {
  description = "(Optional) The symmetric AWS KMS customer master key (CMK) used to encrypt data stored on your WorkSpace. Amazon WorkSpaces does not support asymmetric CMKs"
  type        = string
  default     = "alias/aws/workspaces"
}

variable "ws_compute_type_name" {
  description = "(Optional) The compute type. For more information, see Amazon WorkSpaces Bundles. Valid values are VALUE, STANDARD, PERFORMANCE, POWER, GRAPHICS, POWERPRO and GRAPHICSPRO"
  type        = string
  default     = "VALUE"
}

variable "ws_user_volume_size_gib" {
  description = "(Optional) The size of the user storage"
  type        = number
  default     = 10
}

variable "ws_root_volume_size_gib" {
  description = "(Optional) The size of the root volume"
  type        = number
  default     = 80
}

variable "ws_running_mode" {
  description = "(Optional) The running mode. For more information, see Manage the WorkSpace Running Mode. Valid values are AUTO_STOP and ALWAYS_ON"
  type        = string
  default     = "AUTO_STOP"
}

variable "ws_running_mode_auto_stop_timeout_in_minutes" {
  description = "(Optional) The running mode. For more information, see Manage the WorkSpace Running Mode. Valid values are AUTO_STOP and ALWAYS_ON"
  type        = number
  default     = 60
}

variable "ws_email_domain" {
  description = "The email domain to append to the username to generate the email address"
  type        = string
  default     = ""
}

variable "ws_user_names" {
  description = "(Required) The user name of the user for the WorkSpace. This user name must exist in the directory for the WorkSpace"
  type        = list(string)
  default     = [""]
}

variable "ws_bundle_id" {
  description = "(Required) The ID of the bundle for the WorkSpace"
  type        = string
  default     = ""
}

variable "ws_directory_id" {
  description = "(Required) The ID of the directory for the WorkSpace"
  type        = string
  default     = ""
}

variable "ws_admin_control" {
  description = "(Optional) If true no workspaces will be created by module, they would be left for admin creation"
  type        = bool
  default     = false
}

locals {
  ws_admin_usernames = var.ws_admin_control ? [] : var.ws_user_names
}
# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

module "ds" {
  source                             = "git::https://github.com/gravicore/terraform-gravicore-modules/aws/ds?ref=GDEV-230-create-directory-service-module"
  create                             = var.create && var.directory_id == "" ? true : false
  directory_dns_name                 = var.ds_directory_dns_name
  password                           = var.ds_password
  password_parameter_key             = var.ds_password_parameter_key
  username_parameter_key             = var.ds_username_parameter_key
  size                               = var.ds_size
  subnet_ids                         = coalesce(var.ds_subnet_ids, var.subnet_ids)
  connect_settings_customer_username = var.ds_connect_settings_customer_username
  connect_settings_customer_dns_ips  = var.ds_connect_settings_customer_dns_ips
  alias                              = var.ds_alias
  description                        = var.ds_description
  short_name                         = var.ds_short_name
  enable_sso                         = var.ds_enable_sso
  type                               = var.ds_type
  edition                            = var.ds_edition
  name                               = var.name
  terraform_module                   = var.terraform_module
  aws_region                         = var.aws_region
  namespace                          = var.namespace
  environment                        = var.environment
  stage                              = var.stage
  repository                         = var.repository
  tags                               = local.tags
}

resource "aws_workspaces_ip_group" "default" {
  count       = var.create && var.ip_group_rules != null ? 1 : 0
  name        = local.module_prefix
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
  directory_id = var.directory_id != "" ? var.directory_id : module.ds.id
  subnet_ids   = var.subnet_ids

  tags = local.tags

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

  depends_on = [
  ]
}

data "aws_iam_policy_document" "workspaces" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["workspaces.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "workspaces_default" {
  name               = "workspaces_DefaultRole"
  assume_role_policy = data.aws_iam_policy_document.workspaces.json
}

resource "aws_iam_role_policy_attachment" "workspaces_default_service_access" {
  role       = aws_iam_role.workspaces_default.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonWorkSpacesServiceAccess"
}

resource "aws_iam_role_policy_attachment" "workspaces_default_self_service_access" {
  role       = aws_iam_role.workspaces_default.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonWorkSpacesSelfServiceAccess"
}

resource "aws_workspaces_workspace" "default" {
  directory_id = var.ws_directory_id
  bundle_id    = var.ws_bundle_id
  for_each     = toset(local.ws_admin_usernames)
  user_name    = each.key

  root_volume_encryption_enabled = var.ws_root_volume_encryption_enabled
  user_volume_encryption_enabled = var.ws_user_volume_encryption_enabled
  volume_encryption_key          = var.ws_volume_encryption_key

  workspace_properties {
    compute_type_name                         = var.ws_compute_type_name
    user_volume_size_gib                      = var.ws_user_volume_size_gib
    root_volume_size_gib                      = var.ws_root_volume_size_gib
    running_mode                              = var.ws_running_mode
    running_mode_auto_stop_timeout_in_minutes = var.ws_running_mode_auto_stop_timeout_in_minutes
  }

  tags = concat(local.tags, { "user_email" = join("@", [each.key, var.ws_email_domain]) })
}
# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "ws_id" {
  description = "TThe workspaces ID"
  value       = concat(aws_workspaces_workspace.default.*.id, [""])[0]
}

output "ws_ip_address" {
  description = "The IP address of the WorkSpace"
  value       = concat(aws_workspaces_workspace.default.*.id, [""])[0]
}

output "ws_computer_name" {
  description = "The name of the WorkSpace, as seen by the operating system"
  value       = concat(aws_workspaces_workspace.default.*.id, [""])[0]
}

output "ws_state" {
  description = "The operational state of the WorkSpace"
  value       = concat(aws_workspaces_workspace.default.*.id, [""])[0]
}
