resource "aws_route53_zone" "vpc" {
  provider = "aws.master"
  name     = "${local.dns_zone_name}.${data.terraform_remote_state.master_account.parent_domain_name}"
  comment  = "Private DNS zone for ${local.dns_zone_name} VPC"

  vpc {
    vpc_id = "${module.vpc.vpc_id}"
  }

  tags = "${local.tags}"
}

output "zone_id" {
  value = "${aws_route53_zone.vpc.zone_id}"
}

output "name_servers" {
  value = "${aws_route53_zone.vpc.name_servers}"
}
