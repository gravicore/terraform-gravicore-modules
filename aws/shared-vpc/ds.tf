# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES
# ----------------------------------------------------------------------------------------------------------------------

variable "create_ds" {
  default = "true"
}

variable "ds_subdomain_name" {
  default = "ds"
}

variable "ds_short_name" {}

locals {
  ds_alias           = "${replace("${var.namespace}-${var.ds_subdomain_name}-${var.stage}", "-prd", "")}"
  vpc_subdomain_name = "${replace("${var.stage}.${var.environment}", "prd.", "")}"
  ds_zone_name       = "${replace("${var.stage}.${var.ds_subdomain_name}.${var.parent_domain_name}", "prd.", "")}"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

locals {
  module_ds_ssm_param_password_tags = "${merge(local.tags, map(
    "TerraformModule", "github.com/cloudposse/terraform-aws-ssm-parameter-store",
    "TerraformModuleVersion", "0.1.5"))}"
}

module "ds_ssm_param_secret" {
  source = "git::https://github.com/cloudposse/terraform-aws-ssm-parameter-store?ref=0.1.5"

  parameter_read = ["/${local.stage_prefix}/${var.name}-ds-secret"]
}

# name - (Required) The fully qualified name for the directory, such as corp.example.com
# password - (Required) The password for the directory administrator or connector user.
# vpc_settings - (Required for SimpleAD and MicrosoftAD) VPC related information about the directory. Fields documented below.
#     subnet_ids - (Required) The identifiers of the subnets for the directory servers (2 subnets in 2 different AZs).
#     vpc_id - (Required) The identifier of the VPC that the directory is in.
resource "aws_directory_service_directory" "ad" {
  count = "${var.create_ds == "true" ? 1 : 0}"
  name  = "${local.ds_zone_name}"
  tags  = "${local.tags}"

  type     = "MicrosoftAD"
  password = "${lookup(module.ds_ssm_param_secret.map, format("/%s/%s-ds-secret", local.stage_prefix, var.name))}"

  vpc_settings {
    vpc_id     = "${module.vpc.vpc_id}"
    subnet_ids = ["${module.vpc.private_subnets}"]
  }

  alias       = "${local.ds_alias}"
  short_name  = "${var.ds_short_name}"
  description = "${join(" ", list(var.desc_prefix, "Shared Microsoft AD Directory Service"))}"
  enable_sso  = "false"
  edition     = "Standard"
}

resource "aws_vpc_dhcp_options" "ds" {
  count = "${var.create_ds == "true" ? 1 : 0}"
  tags  = "${local.tags}"

  domain_name          = "${aws_directory_service_directory.ad.name}"
  domain_name_servers  = ["${aws_directory_service_directory.ad.dns_ip_addresses}"]
  ntp_servers          = ["${aws_directory_service_directory.ad.dns_ip_addresses}"]
  netbios_name_servers = ["${aws_directory_service_directory.ad.dns_ip_addresses}"]
  netbios_node_type    = 2
}

# DS CNAME on parent domain
# zone_id - (Required) The ID of the hosted zone to contain this record.
# name - (Required) The name of the record.
# type - (Required) The record type. Valid values are A, AAAA, CAA, CNAME, MX, NAPTR, NS, PTR, SOA, SPF, SRV and TXT.
# ttl - (Required for non-alias records) The TTL of the record.
# records - (Required for non-alias records) A string list of records. To specify a single record value longer than 255 characters such as a TXT record for DKIM, add \"\" inside the Terraform configuration string (e.g. "first255characters\"\"morecharacters").
# resource "aws_route53_record" "aws" {
#   provider = "aws.master"

#   zone_id = "${aws_route53_zone.parent.zone_id}"
#   name    = "aws"
#   type    = "CNAME"
#   ttl     = "60"
#   records = ["${local.ds_alias}.awsapps.com"]
# }

# Allow Directory Services to login to console

data "aws_iam_policy_document" "ds_service_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ds.amazonaws.com"]
    }
  }
}

# Default read-only access

resource "aws_iam_role" "ds_viewer" {
  name               = "${local.ds_alias}-viewer"
  description        = "${join(" ", list(var.desc_prefix, "Directory Services AWS Delegated Viewer"))}"
  assume_role_policy = "${data.aws_iam_policy_document.ds_service_assume_role.json}"
}

resource "aws_iam_role_policy_attachment" "ds_viewer" {
  role       = "${aws_iam_role.ds_viewer.id}"
  policy_arn = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
}

# Restricted Administrator

resource "aws_iam_role" "ds_restricted_administrator" {
  name               = "${local.ds_alias}-restricted-administrator"
  description        = "${join(" ", list(var.desc_prefix, "Directory Services AWS Delegated Restricted Administrator"))}"
  assume_role_policy = "${data.aws_iam_policy_document.ds_service_assume_role.json}"
}

resource "aws_iam_role_policy_attachment" "ds_restricted_administrator" {
  role       = "${aws_iam_role.ds_restricted_administrator.id}"
  policy_arn = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "ds_restricted_administrator_workspaces" {
  role       = "${aws_iam_role.ds_restricted_administrator.id}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonWorkSpacesAdmin"
}

resource "aws_iam_role_policy_attachment" "ds_restricted_administrator_workdocs" {
  role       = "${aws_iam_role.ds_restricted_administrator.id}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonZocaloFullAccess"
}

# Administrator

resource "aws_iam_role" "ds_administrator" {
  name               = "${local.ds_alias}-administrator"
  description        = "${join(" ", list(var.desc_prefix, "Directory Services AWS Delegated Administrator"))}"
  assume_role_policy = "${data.aws_iam_policy_document.ds_service_assume_role.json}"
}

resource "aws_iam_role_policy_attachment" "ds_administrator" {
  role       = "${aws_iam_role.ds_administrator.id}"
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "ds_directory_id" {
  value = "${join("", aws_directory_service_directory.ad.*.id)}"
}

output "ds_access_url" {
  value = "${format("https://%s", join("", aws_directory_service_directory.ad.*.access_url))}"
}

output "ds_access_console_url" {
  value = "${format("https://%s/console", join("", aws_directory_service_directory.ad.*.access_url))}"
}

output "ds_dns_ip_addresses" {
  value = "${aws_directory_service_directory.ad.*.dns_ip_addresses}"
}

output "ds_security_group_id" {
  value = "${join("", aws_directory_service_directory.ad.*.security_group_id)}"
}

output "ds_domain_name" {
  value = "${join("", aws_directory_service_directory.ad.*.name)}"
}

output "ds_dhcp_options_id" {
  description = "The ID of the DHCP Options Set."
  value       = "${join("", aws_vpc_dhcp_options.ds.*.id)}"
}

output "ds_dhcp_options_domain_name" {
  description = "The suffix domain name to use by default when resolving non Fully Qualified Domain Names. In other words, this is what ends up being the search value in the /etc/resolv.conf file."
  value       = "${join("", aws_directory_service_directory.ad.*.name)}"
}

output "ds_dhcp_options_domain_name_servers" {
  description = "List of name servers to configure in /etc/resolv.conf. If you want to use the default AWS nameservers you should set this to AmazonProvidedDNS."
  value       = "${aws_directory_service_directory.ad.*.dns_ip_addresses}"
}

output "ds_dhcp_options_ntp_servers" {
  description = "List of NTP servers to configure."
  value       = "${aws_directory_service_directory.ad.*.dns_ip_addresses}"
}

output "ds_dhcp_options_netbios_name_servers" {
  description = "List of NETBIOS name servers."
  value       = "${aws_directory_service_directory.ad.*.dns_ip_addresses}"
}

output "ds_dhcp_options_netbios_node_type" {
  description = "The NetBIOS node type (1, 2, 4, or 8). AWS recommends to specify 2 since broadcast and multicast are not supported in their network. For more information about these node types, see RFC 2132."
  value       = "2"
}
