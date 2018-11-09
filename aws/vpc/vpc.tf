locals {
  module_vpc_tags = "${merge(local.tags, map(
    "TerraformModule", "github.com/terraform-aws-modules/terraform-aws-vpc",
    "TerraformModuleVersion", "v1.46.0"))}"
}

module "vpc" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=v1.46.0"
  name   = "${local.name_prefix}"
  tags   = "${local.module_vpc_tags}"

  azs                     = ["${var.aws_region}a", "${var.aws_region}b"]
  cidr                    = "${var.cidr_network}.0.0/16"
  private_subnets         = ["${var.cidr_network}.0.0/19", "${var.cidr_network}.32.0/19"]
  public_subnets          = ["${var.cidr_network}.128.0/20", "${var.cidr_network}.144.0/20"]
  enable_nat_gateway      = true
  single_nat_gateway      = true
  map_public_ip_on_launch = false
  enable_dns_hostnames    = true
}
