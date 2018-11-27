# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_route53_zone" "parent" {
  count = "${var.create == "true" ? 1 : 0}"
  name  = "${var.parent_domain_name}"
  tags  = "${local.tags}"
}

resource "aws_route53_record" "parent_ns" {
  count   = "${var.create == "true" ? 1 : 0}"
  zone_id = "${join("", aws_route53_zone.parent.*.zone_id)}"
  name    = "${join("", aws_route53_zone.parent.*.name)}"
  type    = "NS"
  ttl     = "60"

  records = [
    "${aws_route53_zone.parent.name_servers.0}",
    "${aws_route53_zone.parent.name_servers.1}",
    "${aws_route53_zone.parent.name_servers.2}",
    "${aws_route53_zone.parent.name_servers.3}",
  ]
}

resource "aws_route53_record" "parent_soa" {
  count   = "${var.create == "true" ? 1 : 0}"
  zone_id = "${join("", aws_route53_zone.parent.*.id)}"
  name    = "${join("", aws_route53_zone.parent.*.name)}"
  type    = "SOA"
  ttl     = "30"

  records = [
    "${aws_route53_zone.parent.name_servers.0}. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400",
  ]
}

# locals {
#   cli_flags = "--hosted-zone-id ${data.aws_route53_zone.parent.id} --vpc VPCRegion=${var.aws_region},VPCId=${module.vpc.vpc_id}"
# }

# module "create_vpc_association_authorization" {
#   # source = "git::https://github.com/opetch/terraform-aws-cli-resource//?ref=master"
#   source = "../cli-resource"
#   create = "${1 - local.is_master_account}"

#   account_id  = "${var.master_account_id}"                                            # Account with the private hosted zone
#   role        = "grv_deploy_svc"
#   cmd         = "aws route53 create-vpc-association-authorization ${local.cli_flags}"
#   destroy_cmd = "aws route53 delete-vpc-association-authorization ${local.cli_flags}"
# }

# module "associate_vpc_with_zone" {
#   # source = "git::https://github.com/opetch/terraform-aws-cli-resource//?ref=master"
#   source = "../cli-resource"
#   create = "${1 - local.is_master_account}"

#   # Uses the default provider account id if no account id is passed in
#   role        = "OrganizationAccountAccessRole"
#   cmd         = "aws route53 associate-vpc-with-hosted-zone ${local.cli_flags}"
#   destroy_cmd = "aws route53 disassociate-vpc-from-hosted-zone ${local.cli_flags}"

#   # Require that the above resource is created first 
#   dependency_ids = ["${module.create_vpc_association_authorization.id}"]
# }

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "dns_parent_zone_id" {
  value = "${join("", aws_route53_zone.parent.*.zone_id)}"
}

output "dns_parent_zone_name_servers" {
  value = "${aws_route53_zone.parent.name_servers}"
}
