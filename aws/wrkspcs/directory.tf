# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "directory_id" {
  type        = string
  default     = ""
  description = "(Required) The directory identifier for registration in WorkSpaces service"
}

variable "subnet_ids" {
  type        = list(string)
  default     = null
  description = "(Optional) The identifiers of the subnets where the directory resides"
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
  default     = "Small"
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
  default     = "Directory Service"
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

variable "allow_ingress_icmp" {
  description = "(Optional) List of Security Group ingress CIDRs for RDP"
  type        = bool
  default     = false
}

variable "ingress_icmp_cidrs" {
  description = "(Optional) List of Security Group ingress CIDRs for ICMP"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allow_ingress_sccm" {
  description = "(Optional) List of Security Group ingress CIDRs for RDP"
  type        = bool
  default     = false
}

variable "ingress_sccm_cidrs" {
  description = "(Optional) List of Security Group ingress CIDRs for RDP"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allow_ingress_rdp" {
  description = "(Optional) List of Security Group ingress CIDRs for RDP"
  type        = bool
  default     = false
}

variable "ingress_rdp_cidrs" {
  description = "(Optional) List of Security Group ingress CIDRs for RDP"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allow_ingress_ssh" {
  description = "(Optional) List of Security Group ingress CIDRs for RDP"
  type        = bool
  default     = false
}

variable "ingress_ssh_cidrs" {
  description = "(Optional) List of Security Group ingress CIDRs for SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ingress_rules" {
  type        = list(any)
  default     = []
  description = <<EOF
  Security Group ingress CIDRs. Protocol, From Port, To Port
  A rule statement used to run the rules that are defined in a managed rule group. A list of maps with the following syntax:

  ingress_rules = [
    [
      "tcp",          (string)            (Required) Protocol. If you select a protocol of -1 (semantically equivalent to all, which is not a valid value here), you must specify a from_port and to_port equal to 0. The supported values are defined in the IpProtocol argument on the IpPermission, https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_IpPermission.html, API reference. This argument is normalized to a lowercase value to match the AWS API requirement when using with Terraform 0.12.x and above, please make sure that the value of the protocol is specified as lowercase when using with older version of Terraform to avoid an issue during upgrade
      0,              (number)            (Required) Start port (or ICMP type number if protocol is icmp or icmpv6)
      0,              (number)            (Required) End range port (or ICMP code if protocol is icmp)
      [
        "0.0.0.0/0"   (list of strings)   (Optional) List of CIDR blocks
      ]
    ]
  ]
EOF 
}

variable "egress_rules" {
  type = list(any)
  default = [
    ["all", 0, 0, ["0.0.0.0/0"]],
  ]
  description = <<EOF
  Security Group egress CIDRs. Protocol, From Port, To Port
  A rule statement used to run the rules that are defined in a managed rule group. A list of maps with the following syntax:

  egress_rules = [
    [
      "tcp",          (string)            (Required) Protocol. If you select a protocol of -1 (semantically equivalent to all, which is not a valid value here), you must specify a from_port and to_port equal to 0. The supported values are defined in the IpProtocol argument on the IpPermission, https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_IpPermission.html, API reference. This argument is normalized to a lowercase value to match the AWS API requirement when using with Terraform 0.12.x and above, please make sure that the value of the protocol is specified as lowercase when using with older version of Terraform to avoid an issue during upgrade
      0,              (number)            (Required) Start port (or ICMP type number if protocol is icmp)
      0,              (number)            (Required) End range port (or ICMP code if protocol is icmp)
      [
        "0.0.0.0/0"   (list of strings)   (Optional) List of CIDR blocks
      ]
    ]
  ]
EOF
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

module "ds" {
  source      = "git::https://github.com/gravicore/terraform-gravicore-modules.git//aws/ds?ref=0.38.0"
  create      = var.create && var.directory_id == "" ? true : false
  name        = var.name
  tags        = local.tags
  description = var.ds_description

  aws_region                         = var.aws_region
  terraform_module                   = var.terraform_module
  namespace                          = var.namespace
  environment                        = var.environment
  stage                              = var.stage
  repository                         = var.repository
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
  count        = var.create ? 1 : 0
  directory_id = var.directory_id != "" ? var.directory_id : module.ds.id
}

resource "aws_security_group_rule" "ds_ingress" {
  count                    = var.create ? 1 : 0
  security_group_id        = concat(aws_security_group.default.*.id, [""])[0]
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "all"
  source_security_group_id = concat(data.aws_directory_service_directory.default.*.security_group_id, [""])[0]
}

resource "aws_security_group_rule" "allow_icmp" {
  count             = var.create && var.allow_ingress_icmp ? 1 : 0
  security_group_id = concat(aws_security_group.default.*.id, [""])[0]
  type              = "ingress"
  from_port         = "-1"
  to_port           = "-1"
  protocol          = "icmp"
  cidr_blocks       = var.ingress_icmp_cidrs
}

resource "aws_security_group_rule" "allow_rdp" {
  count             = var.create && var.allow_ingress_rdp ? 1 : 0
  security_group_id = concat(aws_security_group.default.*.id, [""])[0]
  type              = "ingress"
  from_port         = "3389"
  to_port           = "3389"
  protocol          = "tcp"
  cidr_blocks       = var.ingress_rdp_cidrs
}

resource "aws_security_group_rule" "allow_ssh" {
  count             = var.create && var.allow_ingress_ssh ? 1 : 0
  security_group_id = concat(aws_security_group.default.*.id, [""])[0]
  type              = "ingress"
  from_port         = "22"
  to_port           = "22"
  protocol          = "tcp"
  cidr_blocks       = var.ingress_ssh_cidrs
}

locals {
  ingress_sccm = [
    ["tcp", 443, 443],
    ["udp", 9, 9],
    ["udp", 25536, 25536],
    ["udp", 8004, 8004],
    ["tcp", 8003, 8003],
  ]
}

resource "aws_security_group_rule" "allow_sccm" {
  count             = var.create && var.allow_ingress_sccm ? 1 : 0
  security_group_id = concat(aws_security_group.default.*.id, [""])[0]
  type              = "ingress"
  from_port         = element(local.ingress_sccm[count.index], 1)
  to_port           = element(local.ingress_sccm[count.index], 2)
  protocol          = element(local.ingress_sccm[count.index], 0)
  cidr_blocks       = var.ingress_sccm_cidrs
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

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "security_group_id" {
  description = "The security group ID of the WorkSpaces"
  value       = concat(aws_security_group.default.*.id, [""])[0]
}

output "ip_group_id" {
  description = "The ID of the workspaces IP group"
  value       = concat(aws_workspaces_ip_group.default.*.id, [""])[0]
}
