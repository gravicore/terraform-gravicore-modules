resource "aws_route53_zone" "vpc" {
  count    = "${local.is_master_account}"
  provider = "aws.master"

  name    = "${local.dns_zone_name}.${data.terraform_remote_state.master_account.parent_domain_name}"
  comment = "Private DNS zone for ${local.dns_zone_name} VPC"

  vpc {
    vpc_id = "${module.vpc.vpc_id}"
  }

  tags = "${local.tags}"
}

locals {
  cli_flags = "--hosted-zone-id SOME_HOSTEDZONEID --vpc VPCRegion=${var.aws_region},VPCId=${module.vpc.vpc_id}"
}

module "create_vpc_association_authorization" {
  count  = "${1 - local.is_master_account}"
  source = "git::https://github.com/opetch/terraform-aws-cli-resource//?ref=master"

  account_id  = "${var.master_account_id}"                                            # Account with the private hosted zone
  role        = "grv_deploy_svc"
  cmd         = "aws route53 create-vpc-association-authorization ${local.cli_flags}"
  destroy_cmd = "aws route53 delete-vpc-association-authorization ${local.cli_flags}"
}

module "associate_vpc_with_zone" {
  count  = "${1 - local.is_master_account}"
  source = "git::https://github.com/opetch/terraform-aws-cli-resource//?ref=master"

  # Uses the default provider account id if no account id is passed in
  role        = "OrganizationAccountAccessRole"
  cmd         = "aws route53 associate-vpc-with-hosted-zone ${local.cli_flags}"
  destroy_cmd = "aws route53 disassociate-vpc-from-hosted-zone ${local.cli_flags}"

  # Require that the above resource is created first 
  dependency_ids = ["${module.create_vpc_association_authorization.id}"]
}

output "zone_id" {
  value = "${aws_route53_zone.vpc.zone_id}"
}

output "name_servers" {
  value = "${aws_route53_zone.vpc.name_servers}"
}
