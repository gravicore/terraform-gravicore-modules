# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "cidr_network" {
  default = "10.0"
}

variable "associate_ds" {
  default = true
  type    = bool
}

variable "shared_vpc_remote_state_path" {
  default = "master/prd/shared-vpc"
}

variable "kms_arn" {
  type        = string
  default     = "alias/parameter_store_key"
  description = "The ARN of a KMS key used to encrypt and decrypt SecretString values"
}

variable "map_public_ip_on_launch" {
  description = "Should be false if you do not want to auto-assign public IP on launch"
  default     = false
  type        = bool
}

variable "enable_nat_gateway" {
  description = "Should be true if you want to provision NAT Gateways for each of your private networks"
  default     = false
  type        = bool
}

variable "single_nat_gateway" {
  description = "Should be true if you want to provision a single shared NAT Gateway across all of your private networks"
  default     = false
  type        = bool
}

variable "one_nat_gateway_per_az" {
  description = "Should be true if you want only one NAT Gateway per availability zone. Requires `var.azs` to be set, and the number of `public_subnets` created to be greater than or equal to the number of availability zones specified in `var.azs`."
  default     = false
  type        = bool
}

variable "enable_dynamodb_endpoint" {
  description = "Should be true if you want to provision a DynamoDB endpoint to the VPC"
  default     = true
  type        = bool
}
variable "enable_s3_endpoint" {
  description = "Should be true if you want to provision an S3 endpoint to the VPC"
  default     = true
  type        = bool
}

variable "enable_sqs_endpoint" {
  description = "Should be true if you want to provision an SQS endpoint to the VPC"
  default     = false
  type        = bool
}

variable "enable_ssm_endpoint" {
  description = "Should be true if you want to provision an SSM endpoint to the VPC"
  default     = false
  type        = bool
}

variable "enable_ssmmessages_endpoint" {
  description = "Should be true if you want to provision a SSMMESSAGES endpoint to the VPC"
  default     = false
  type        = bool
}

variable "enable_apigw_endpoint" {
  description = "Should be true if you want to provision an api gateway endpoint to the VPC"
  default     = false
  type        = bool
}

variable "enable_ec2_endpoint" {
  description = "Should be true if you want to provision an EC2 endpoint to the VPC"
  default     = false
  type        = bool
}

variable "enable_ec2messages_endpoint" {
  description = "Should be true if you want to provision an EC2MESSAGES endpoint to the VPC"
  default     = false
  type        = bool
}

variable "enable_ecr_api_endpoint" {
  description = "Should be true if you want to provision an ecr api endpoint to the VPC"
  default     = false
  type        = bool
}

variable "enable_ecr_dkr_endpoint" {
  description = "Should be true if you want to provision an ecr dkr endpoint to the VPC"
  default     = false
  type        = bool
}

variable "enable_kms_endpoint" {
  description = "Should be true if you want to provision a KMS endpoint to the VPC"
  default     = false
  type        = bool
}

variable "enable_ecs_endpoint" {
  description = "Should be true if you want to provision a ECS endpoint to the VPC"
  default     = false
  type        = bool
}

variable "enable_ecs_agent_endpoint" {
  description = "Should be true if you want to provision a ECS Agent endpoint to the VPC"
  default     = false
  type        = bool
}

variable "enable_ecs_telemetry_endpoint" {
  description = "Should be true if you want to provision a ECS Telemetry endpoint to the VPC"
  default     = false
  type        = bool
}

variable "enable_dns_hostnames" {
  description = "Should be true to enable DNS hostnames in the VPC"
  default     = true
  type        = bool
}

variable "enable_dns_support" {
  description = "Should be true to enable DNS support in the VPC"
  default     = true
  type        = bool
}

data "terraform_remote_state" "shared_vpc" {
  backend = "s3"

  config = {
    region         = var.aws_region
    bucket         = "${var.namespace}-master-prd-tf-state-${var.master_account_id}"
    encrypt        = true
    key            = "${var.shared_vpc_remote_state_path}/terraform.tfstate"
    dynamodb_table = "${var.namespace}-master-prd-tf-state-lock"
    role_arn       = "arn:aws:iam::${var.master_account_id}:role/grv_deploy_svc"
  }
}

locals {
  vpc_subdomain_name = replace("${var.stage}.${var.environment}", "prd.", "")
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

# Create a default key/pair for public and private instances

locals {
  module_ssh_key_pair_public_tags = merge(
    local.tags,
    {
      "TerraformModule"        = "cloudposse/terraform-aws-key-pair"
      "TerraformModuleVersion" = "0.4.0"
    },
  )
}

module "ssh_key_pair_public" {
  source    = "git::https://github.com/cloudposse/terraform-aws-key-pair.git?ref=0.4.0"
  namespace = var.namespace
  stage     = var.stage
  name      = "${var.environment}-${var.name}-public"
  tags      = local.module_ssh_key_pair_public_tags

  ssh_public_key_path   = "${pathexpand("~/.ssh")}/${var.namespace}"
  generate_ssh_key      = var.create
  private_key_extension = ".pem"
  public_key_extension  = ".pub"
  chmod_command         = "chmod 600 %v"
}

locals {
  module_ssh_key_pair_private_tags = merge(
    local.tags,
    {
      "TerraformModule"        = "gravicore/terraform-gravicore-modules/aws/spoke-vpc/key-pair"
      "TerraformModuleVersion" = ""
    },
  )
}

module "ssh_key_pair_private" {
  source    = "./key-pair"
  namespace = var.namespace
  stage     = var.stage
  name      = "${var.environment}-${var.name}-private"
  tags      = local.module_ssh_key_pair_private_tags

  ssh_public_key_path   = "${pathexpand("~/.ssh")}/${var.namespace}"
  generate_ssh_key      = var.create
  private_key_extension = ".pem"
  public_key_extension  = ".pub"
  chmod_command         = "chmod 600 %v"
}

locals {
  ssh_secret_ssm_write = [
    {
      name      = "/${local.stage_prefix}/${var.name}-private-pem"
      value     = module.ssh_key_pair_private.private_key
      type      = "SecureString"
      overwrite = "true"
      description = join(
        " ",
        [
          var.desc_prefix,
          "Private SSH Key for EC2 Instances in Private VPC Subnet",
        ],
      )
    },
    {
      name      = "/${local.stage_prefix}/${var.name}-private-pub"
      value     = module.ssh_key_pair_private.public_key
      type      = "SecureString"
      overwrite = "true"
      description = join(
        " ",
        [
          var.desc_prefix,
          "Public SSH Key for EC2 Instances in Private VPC Subnet",
        ],
      )
    },
  ]

  # `ssh_secret_ssm_write_count` needs to be updated if `ssh_secret_ssm_write` changes
  ssh_secret_ssm_write_count = 2
}

resource "aws_ssm_parameter" "default" {
  count = var.create ? local.ssh_secret_ssm_write_count : 0
  name  = local.ssh_secret_ssm_write[count.index]["name"]
  description = lookup(
    local.ssh_secret_ssm_write[count.index],
    "description",
    local.ssh_secret_ssm_write[count.index]["name"],
  )
  type = lookup(
    local.ssh_secret_ssm_write[count.index],
    "type",
    "SecureString",
  )
  key_id = lookup(
    local.ssh_secret_ssm_write[count.index],
    "type",
    "SecureString",
  ) == "SecureString" && length(var.kms_arn) > 0 ? var.kms_arn : ""
  value = local.ssh_secret_ssm_write[count.index]["value"]
  overwrite = lookup(
    local.ssh_secret_ssm_write[count.index],
    "overwrite",
    "false",
  )
  allowed_pattern = lookup(
    local.ssh_secret_ssm_write[count.index],
    "allowed_pattern",
    "",
  )
  tags = local.tags
}

locals {
  module_vpc_tags = merge(
    local.tags,
    {
      "TerraformModule"        = "terraform-aws-modules/terraform-aws-vpc"
      "TerraformModuleVersion" = "v2.15.0"
    },
  )
}

module "vpc" {
  source     = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc?ref=v2.15.0"
  create_vpc = var.create ? true : false
  name       = local.module_prefix
  tags       = local.module_vpc_tags

  azs                           = ["${var.aws_region}a", "${var.aws_region}b"]
  cidr                          = "${var.cidr_network}.0.0/16"
  private_subnets               = ["${var.cidr_network}.0.0/19", "${var.cidr_network}.32.0/19"]
  public_subnets                = ["${var.cidr_network}.128.0/20", "${var.cidr_network}.144.0/20"]
  map_public_ip_on_launch       = var.map_public_ip_on_launch
  enable_nat_gateway            = var.enable_nat_gateway
  single_nat_gateway            = var.single_nat_gateway
  one_nat_gateway_per_az        = var.one_nat_gateway_per_az
  enable_dynamodb_endpoint      = var.enable_dynamodb_endpoint
  enable_s3_endpoint            = var.enable_s3_endpoint
  enable_dns_support            = var.enable_dns_support
  enable_dns_hostnames          = var.enable_dns_hostnames
  enable_sqs_endpoint           = var.enable_sqs_endpoint
  enable_ssm_endpoint           = var.enable_ssm_endpoint
  enable_ssmmessages_endpoint   = var.enable_ssmmessages_endpoint
  enable_apigw_endpoint         = var.enable_apigw_endpoint
  enable_ec2_endpoint           = var.enable_ec2_endpoint
  enable_ecr_api_endpoint       = var.enable_ecr_api_endpoint
  enable_ecr_dkr_endpoint       = var.enable_ecr_dkr_endpoint
  enable_kms_endpoint           = var.enable_kms_endpoint
  enable_ecs_endpoint           = var.enable_ecs_endpoint
  enable_ecs_agent_endpoint     = var.enable_ecs_agent_endpoint
  enable_ecs_telemetry_endpoint = var.enable_ecs_telemetry_endpoint

  enable_dhcp_options               = var.associate_ds ? true : false
  dhcp_options_domain_name          = data.terraform_remote_state.shared_vpc.outputs.ds_domain_name
  dhcp_options_domain_name_servers  = data.terraform_remote_state.shared_vpc.outputs.ds_dns_ip_addresses
  dhcp_options_ntp_servers          = data.terraform_remote_state.shared_vpc.outputs.ds_dns_ip_addresses
  dhcp_options_netbios_name_servers = data.terraform_remote_state.shared_vpc.outputs.ds_dns_ip_addresses
  dhcp_options_netbios_node_type    = "2"
}

locals {
  is_not_master_account = var.master_account_id != var.account_id ? true : false
}

resource "aws_default_vpc" "default" {
  provider = aws.master
}

resource "aws_route53_zone" "vpc" {
  provider = aws.master
  count    = var.create ? 1 : 0
  tags     = local.tags

  name = local.dns_zone_name
  comment = join(
    " ",
    [
      var.desc_prefix,
      format(
        "VPC Private DNS zone for %s %s",
        local.module_prefix,
        module.vpc.vpc_id,
      ),
    ],
  )

  vpc {
    vpc_id = local.is_not_master_account ? aws_default_vpc.default.id : module.vpc.vpc_id
  }

  lifecycle {
    ignore_changes = [vpc]
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
  vpc_association_cli_flags = "--hosted-zone-id ${aws_route53_zone.vpc[0].zone_id} --vpc VPCRegion=${var.aws_region},VPCId=${module.vpc.vpc_id}"
}

# https://medium.com/@dalethestirling/managing-route53-cross-account-zone-associations-with-terraform-e1e45de8f3ea

resource "null_resource" "create_remote_zone_auth" {
  count = local.is_not_master_account ? 1 : 0

  triggers = {
    zone_id = aws_route53_zone.vpc[0].zone_id
  }

  provisioner "local-exec" {
    when    = create
    command = "aws route53 create-vpc-association-authorization ${local.vpc_association_cli_flags}"
  }

  provisioner "local-exec" {
    when    = create
    command = "echo ====== PRIVATE ZONE ASSOCIATION COMMANDS ====== && echo av ${var.namespace}-${var.environment}-${var.stage} aws route53 associate-vpc-with-hosted-zone ${local.vpc_association_cli_flags} && echo av ${var.namespace} aws route53 disassociate-vpc-from-hosted-zone --hosted-zone-id ${join("", aws_route53_zone.vpc.*.zone_id)} --vpc VPCRegion=${var.aws_region},VPCId=${aws_default_vpc.default.id}"
  }

  provisioner "local-exec" {
    when       = destroy
    command    = "aws route53 delete-vpc-association-authorization ${local.vpc_association_cli_flags}"
    on_failure = continue
  }
}

output "vpc_dns_association_commands" {
  value = [
    "av ${var.namespace}-${var.environment}-${var.stage} aws route53 associate-vpc-with-hosted-zone ${local.vpc_association_cli_flags}",
    "av ${var.namespace} aws route53 disassociate-vpc-from-hosted-zone --hosted-zone-id ${join("", aws_route53_zone.vpc.*.zone_id)} --vpc VPCRegion=${var.aws_region},VPCId=${aws_default_vpc.default.id}",
  ]
}

# resource "null_resource" "associate_with_remote_zone" {
#   count      = "${local.is_not_master_account ? 1 : 0}"
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
#   count = "${local.is_not_master_account ? 1 : 0}"

#   # provider = "aws.master"

#   depends_on = ["null_resource.create_remote_zone_auth"]
#   zone_id = "${aws_route53_zone.vpc.zone_id}"
#   vpc_id  = "${module.vpc.vpc_id}"
# }

# resource "null_resource" "disassociate_default_vpc" {
#   count = "${local.is_not_master_account ? 1 : 0}"

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
  count    = var.associate_ds ? 1 : 0
  provider = aws.master

  directory_id       = data.terraform_remote_state.shared_vpc.outputs.ds_directory_id
  dns_ips            = [cidrhost(module.vpc.vpc_cidr_block, 2)]
  remote_domain_name = local.dns_zone_name
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

// VPC module outputs

output "vpc_subnet_ids" {
  value = concat(
    module.vpc.private_subnets,
    module.vpc.public_subnets,
    module.vpc.database_subnets,
    module.vpc.redshift_subnets,
    module.vpc.elasticache_subnets,
    module.vpc.intra_subnets,
  )
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "vpc_default_security_group_id" {
  description = "The ID of the security group created by default on VPC creation"
  value       = module.vpc.default_security_group_id
}

output "vpc_default_network_acl_id" {
  description = "The ID of the default network ACL"
  value       = module.vpc.default_network_acl_id
}

output "vpc_default_route_table_id" {
  description = "The ID of the default route table"
  value       = module.vpc.default_route_table_id
}

output "vpc_instance_tenancy" {
  description = "Tenancy of instances spin up within VPC"
  value       = module.vpc.vpc_instance_tenancy
}

output "vpc_enable_dns_support" {
  description = "Whether or not the VPC has DNS support"
  value       = module.vpc.vpc_enable_dns_support
}

output "vpc_enable_dns_hostnames" {
  description = "Whether or not the VPC has DNS hostname support"
  value       = module.vpc.vpc_enable_dns_hostnames
}

output "vpc_main_route_table_id" {
  description = "The ID of the main route table associated with this VPC"
  value       = module.vpc.vpc_main_route_table_id
}

output "vpc_secondary_cidr_blocks" {
  description = "List of secondary CIDR blocks of the VPC"
  value       = module.vpc.vpc_secondary_cidr_blocks
}

output "vpc_private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "vpc_private_subnets_cidr_blocks" {
  description = "List of cidr_blocks of private subnets"
  value       = module.vpc.private_subnets_cidr_blocks
}

output "vpc_public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "vpc_public_subnets_cidr_blocks" {
  description = "List of cidr_blocks of public subnets"
  value       = module.vpc.public_subnets_cidr_blocks
}

output "vpc_public_route_table_ids" {
  description = "List of IDs of public route tables"
  value       = module.vpc.public_route_table_ids
}

output "vpc_private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = module.vpc.private_route_table_ids
}

output "vpc_nat_ids" {
  description = "List of allocation ID of Elastic IPs created for AWS NAT Gateway"
  value       = module.vpc.nat_ids
}

output "vpc_nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = module.vpc.nat_public_ips
}

output "vpc_natgw_ids" {
  description = "List of NAT Gateway IDs"
  value       = module.vpc.natgw_ids
}

output "vpc_igw_id" {
  description = "The ID of the Internet Gateway"
  value       = module.vpc.igw_id
}

output "vpc_endpoint_s3_id" {
  description = "The ID of VPC endpoint for S3"
  value       = module.vpc.vpc_endpoint_s3_id
}

output "vpc_endpoint_s3_pl_id" {
  description = "The prefix list for the S3 VPC endpoint."
  value       = module.vpc.vpc_endpoint_s3_pl_id
}

output "vpc_endpoint_dynamodb_id" {
  description = "The ID of VPC endpoint for DynamoDB"
  value       = module.vpc.vpc_endpoint_dynamodb_id
}

output "vpc_vgw_id" {
  description = "The ID of the VPN Gateway"
  value       = module.vpc.vgw_id
}

output "vpc_endpoint_dynamodb_pl_id" {
  description = "The prefix list for the DynamoDB VPC endpoint."
  value       = module.vpc.vpc_endpoint_dynamodb_pl_id
}

# DNS

output "vpc_dns_zone_id" {
  value = join("", aws_route53_zone.vpc.*.zone_id)
}

output "vpc_dns_zone_name_servers" {
  value = flatten(aws_route53_zone.vpc.*.name_servers)
}

output "vpc_dns_zone_vpc_id" {
  value = module.vpc.vpc_id
}

