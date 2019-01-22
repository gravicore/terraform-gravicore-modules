# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "cidr_network" {
  default = "10.0"
}

variable "associate_ds" {
  default = "true"
}

variable "shared_vpc_remote_state_path" {
  default = "master/prd/shared-vpc"
}

data "terraform_remote_state" "shared_vpc" {
  backend = "s3"

  config {
    region         = "${var.aws_region}"
    bucket         = "${var.namespace}-master-prd-tf-state-${var.master_account_id}"
    encrypt        = true
    key            = "${var.shared_vpc_remote_state_path}/terraform.tfstate"
    dynamodb_table = "${var.namespace}-master-prd-tf-state-lock"
    role_arn       = "arn:aws:iam::${var.master_account_id}:role/grv_deploy_svc"
  }
}

locals {
  vpc_subdomain_name = "${replace("${var.stage}.${var.environment}", "prd.", "")}"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

locals {
  module_vpc_tags = "${merge(local.tags, map(
    "TerraformModule", "terraform-aws-modules/terraform-aws-vpc",
    "TerraformModuleVersion", "v1.46.0"))}"
}

module "vpc" {
  source     = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc?ref=v1.46.0"
  create_vpc = "${var.create == "true" ?  1 : 0}"
  name       = "${local.module_prefix}"
  tags       = "${local.module_vpc_tags}"

  azs                      = ["${var.aws_region}a", "${var.aws_region}b"]
  cidr                     = "${var.cidr_network}.0.0/16"
  private_subnets          = ["${var.cidr_network}.0.0/19", "${var.cidr_network}.32.0/19"]
  public_subnets           = ["${var.cidr_network}.128.0/20", "${var.cidr_network}.144.0/20"]
  map_public_ip_on_launch  = false
  enable_nat_gateway       = false
  enable_dynamodb_endpoint = true
  enable_s3_endpoint       = true
  enable_dns_support       = true
  enable_dns_hostnames     = true

  enable_dhcp_options               = "${var.associate_ds == "true" ? true : false}"
  dhcp_options_domain_name          = "${data.terraform_remote_state.shared_vpc.ds_domain_name}"
  dhcp_options_domain_name_servers  = "${data.terraform_remote_state.shared_vpc.ds_dns_ip_addresses}"
  dhcp_options_ntp_servers          = "${data.terraform_remote_state.shared_vpc.ds_dns_ip_addresses}"
  dhcp_options_netbios_name_servers = "${data.terraform_remote_state.shared_vpc.ds_dns_ip_addresses}"
  dhcp_options_netbios_node_type    = "2"
}

locals {
  is_not_master_account = "${var.master_account_id != var.account_id ? "true" : "false"}"
}

resource "aws_default_vpc" "default" {
  provider = "aws.master"
}

resource "aws_route53_zone" "vpc" {
  provider = "aws.master"
  count    = "${var.create == "true" ? 1 : 0}"
  tags     = "${local.tags}"

  name    = "${local.dns_zone_name}"
  comment = "${join(" ", list(var.desc_prefix, format("VPC Private DNS zone for %s %s", local.module_prefix, module.vpc.vpc_id)))}"

  vpc {
    vpc_id = "${local.is_not_master_account == "true" ? aws_default_vpc.default.id : module.vpc.vpc_id }"
  }

  lifecycle {
    ignore_changes = ["vpc"]
  }
}

# If Master Account
# -----------------

# resource "aws_route53_zone_association" "master_vpc" {
#   count = "${local.is_not_master_account == "false" ? 1 : 0}"

#   zone_id = "${aws_route53_zone.vpc.zone_id}"
#   vpc_id  = "${module.vpc.vpc_id}"
# }

# If Not Master Account
# -----------------

locals {
  vpc_association_cli_flags = "--hosted-zone-id ${aws_route53_zone.vpc.zone_id} --vpc VPCRegion=${var.aws_region},VPCId=${module.vpc.vpc_id}"
}

# https://medium.com/@dalethestirling/managing-route53-cross-account-zone-associations-with-terraform-e1e45de8f3ea

resource "null_resource" "create_remote_zone_auth" {
  count = "${local.is_not_master_account == "true" ? 1 : 0}"

  triggers {
    zone_id = "${aws_route53_zone.vpc.zone_id}"
  }

  provisioner "local-exec" {
    when    = "create"
    command = "aws route53 create-vpc-association-authorization ${local.vpc_association_cli_flags}"
  }

  provisioner "local-exec" {
    when    = "create"
    command = "echo ====== PRIVATE ZONE ASSOCIATION COMMANDS ====== && echo av ${var.namespace}-${var.environment}-${var.stage} aws route53 associate-vpc-with-hosted-zone ${local.vpc_association_cli_flags} && echo av ${var.namespace} aws route53 disassociate-vpc-from-hosted-zone --hosted-zone-id ${join("", aws_route53_zone.vpc.*.zone_id)} --vpc VPCRegion=${var.aws_region},VPCId=${aws_default_vpc.default.id}"
  }

  provisioner "local-exec" {
    when       = "destroy"
    command    = "aws route53 delete-vpc-association-authorization ${local.vpc_association_cli_flags}"
    on_failure = "continue"
  }
}

output "vpc_dns_association_commands" {
  value = [
    "av ${var.namespace}-${var.environment}-${var.stage} aws route53 associate-vpc-with-hosted-zone ${local.vpc_association_cli_flags}",
    "av ${var.namespace} aws route53 disassociate-vpc-from-hosted-zone --hosted-zone-id ${join("", aws_route53_zone.vpc.*.zone_id)} --vpc VPCRegion=${var.aws_region},VPCId=${aws_default_vpc.default.id}",
  ]
}

# resource "null_resource" "associate_with_remote_zone" {
#   count      = "${local.is_not_master_account == "true" ? 1 : 0}"
#   depends_on = ["null_resource.create_remote_zone_auth"]

#   triggers {
#     vpc_id = "${module.vpc.vpc_id}"
#   }

#   provisioner "local-exec" {
#     when    = "create"
#     command = "aws route53 associate-vpc-with-hosted-zone ${local.vpc_association_cli_flags}"
#   }

#   provisioner "local-exec" {
#     when       = "destroy"
#     command    = "aws route53 disassociate-vpc-with-hosted-zone ${local.vpc_association_cli_flags}"
#     on_failure = "continue"
#   }
# }

# resource "aws_route53_zone_association" "spoke_vpc" {
#   count = "${local.is_not_master_account == "true" ? 1 : 0}"

#   # provider = "aws.master"

#   depends_on = ["null_resource.create_remote_zone_auth"]
#   zone_id = "${aws_route53_zone.vpc.zone_id}"
#   vpc_id  = "${module.vpc.vpc_id}"
# }

# resource "null_resource" "disassociate_default_vpc" {
#   count = "${local.is_not_master_account == "true" ? 1 : 0}"

#   triggers {
#     zone_association_id = "${aws_route53_zone_association.spoke_vpc.id}"
#   }

#   provisioner "local-exec" {
#     when    = "create"
#     command = "aws route53 disassociate-vpc-from-hosted-zone --hosted-zone-id ${aws_route53_zone.vpc.zone_id} --vpc VPCRegion=${var.aws_region},VPCId=${aws_default_vpc.default.id}"
#   }
# }

# directory_id - (Required) The id of directory.
# dns_ips - (Required) A list of forwarder IP addresses.
# remote_domain_name - (Required) The fully qualified domain name of the remote domain for which forwarders will be used.
resource "aws_directory_service_conditional_forwarder" "vpc" {
  count    = "${var.associate_ds == "true" ? 1 : 0}"
  provider = "aws.master"

  directory_id       = "${data.terraform_remote_state.shared_vpc.ds_directory_id}"
  dns_ips            = ["${cidrhost(module.vpc.vpc_cidr_block, 2)}"]
  remote_domain_name = "${local.dns_zone_name}"
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

// VPC module outputs

output "vpc_subnet_ids" {
  value = "${concat(
    module.vpc.private_subnets, 
    module.vpc.public_subnets, 
    module.vpc.database_subnets, 
    module.vpc.redshift_subnets,
    module.vpc.elasticache_subnets,
    module.vpc.intra_subnets
  )}"
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = "${module.vpc.vpc_id}"
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = "${module.vpc.vpc_cidr_block}"
}

output "vpc_default_security_group_id" {
  description = "The ID of the security group created by default on VPC creation"
  value       = "${module.vpc.default_security_group_id}"
}

output "vpc_default_network_acl_id" {
  description = "The ID of the default network ACL"
  value       = "${module.vpc.default_network_acl_id}"
}

output "vpc_default_route_table_id" {
  description = "The ID of the default route table"
  value       = "${module.vpc.default_route_table_id}"
}

output "vpc_instance_tenancy" {
  description = "Tenancy of instances spin up within VPC"
  value       = "${module.vpc.vpc_instance_tenancy}"
}

output "vpc_enable_dns_support" {
  description = "Whether or not the VPC has DNS support"
  value       = "${module.vpc.vpc_enable_dns_support}"
}

output "vpc_enable_dns_hostnames" {
  description = "Whether or not the VPC has DNS hostname support"
  value       = "${module.vpc.vpc_enable_dns_hostnames}"
}

output "vpc_main_route_table_id" {
  description = "The ID of the main route table associated with this VPC"
  value       = "${module.vpc.vpc_main_route_table_id}"
}

output "vpc_secondary_cidr_blocks" {
  description = "List of secondary CIDR blocks of the VPC"
  value       = "${module.vpc.vpc_secondary_cidr_blocks}"
}

output "vpc_private_subnets" {
  description = "List of IDs of private subnets"
  value       = "${module.vpc.private_subnets}"
}

output "vpc_private_subnets_cidr_blocks" {
  description = "List of cidr_blocks of private subnets"
  value       = "${module.vpc.private_subnets_cidr_blocks}"
}

output "vpc_public_subnets" {
  description = "List of IDs of public subnets"
  value       = "${module.vpc.public_subnets}"
}

output "vpc_public_subnets_cidr_blocks" {
  description = "List of cidr_blocks of public subnets"
  value       = "${module.vpc.public_subnets_cidr_blocks}"
}

output "vpc_public_route_table_ids" {
  description = "List of IDs of public route tables"
  value       = "${module.vpc.public_route_table_ids}"
}

output "vpc_private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = "${module.vpc.private_route_table_ids}"
}

output "vpc_nat_ids" {
  description = "List of allocation ID of Elastic IPs created for AWS NAT Gateway"
  value       = "${module.vpc.nat_ids}"
}

output "vpc_nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = "${module.vpc.nat_public_ips}"
}

output "vpc_natgw_ids" {
  description = "List of NAT Gateway IDs"
  value       = "${module.vpc.natgw_ids}"
}

output "vpc_igw_id" {
  description = "The ID of the Internet Gateway"
  value       = "${module.vpc.igw_id}"
}

output "vpc_endpoint_s3_id" {
  description = "The ID of VPC endpoint for S3"
  value       = "${module.vpc.vpc_endpoint_s3_id}"
}

output "vpc_endpoint_s3_pl_id" {
  description = "The prefix list for the S3 VPC endpoint."
  value       = "${module.vpc.vpc_endpoint_s3_pl_id}"
}

output "vpc_endpoint_dynamodb_id" {
  description = "The ID of VPC endpoint for DynamoDB"
  value       = "${module.vpc.vpc_endpoint_dynamodb_id}"
}

output "vpc_vgw_id" {
  description = "The ID of the VPN Gateway"
  value       = "${module.vpc.vgw_id}"
}

output "vpc_endpoint_dynamodb_pl_id" {
  description = "The prefix list for the DynamoDB VPC endpoint."
  value       = "${module.vpc.vpc_endpoint_dynamodb_pl_id}"
}

# DNS

output "vpc_dns_zone_id" {
  value = "${join("", aws_route53_zone.vpc.*.zone_id)}"
}

output "vpc_dns_zone_name_servers" {
  value = "${flatten(aws_route53_zone.vpc.*.name_servers)}"
}

output "vpc_dns_zone_vpc_id" {
  value = "${module.vpc.vpc_id}"
}
