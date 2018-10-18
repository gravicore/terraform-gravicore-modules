output "subnet_ids" {
  value = "${concat(module.vpc.private_subnets, module.vpc.public_subnets)}"
}

// VPC module outputs

output "vpc_id" {
  description = "The ID of the VPC"
  value       = "${module.vpc.vpc_id}"
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = "${module.vpc.vpc_cidr_block}"
}

output "default_security_group_id" {
  description = "The ID of the security group created by default on VPC creation"
  value       = "${module.vpc.default_security_group_id}"
}

output "default_network_acl_id" {
  description = "The ID of the default network ACL"
  value       = "${module.vpc.default_network_acl_id}"
}

output "default_route_table_id" {
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

//output "vpc_enable_classiclink" {
//  description = "Whether or not the VPC has Classiclink enabled"
//  value       = "${element(concat(aws_vpc.this.*.enable_classiclink, list("")), 0)}"
//}

output "vpc_main_route_table_id" {
  description = "The ID of the main route table associated with this VPC"
  value       = "${module.vpc.vpc_main_route_table_id}"
}

//output "vpc_ipv6_association_id" {
//  description = "The association ID for the IPv6 CIDR block"
//  value       = "${element(concat(aws_vpc.this.*.ipv6_association_id, list("")), 0)}"
//}
//
//output "vpc_ipv6_cidr_block" {
//  description = "The IPv6 CIDR block"
//  value       = "${element(concat(aws_vpc.this.*.ipv6_cidr_block, list("")), 0)}"
//}

output "vpc_secondary_cidr_blocks" {
  description = "List of secondary CIDR blocks of the VPC"
  value       = "${module.vpc.vpc_secondary_cidr_blocks}"
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = "${module.vpc.private_subnets}"
}

output "private_subnets_cidr_blocks" {
  description = "List of cidr_blocks of private subnets"
  value       = "${module.vpc.private_subnets_cidr_blocks}"
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = "${module.vpc.public_subnets}"
}

output "public_subnets_cidr_blocks" {
  description = "List of cidr_blocks of public subnets"
  value       = "${module.vpc.public_subnets_cidr_blocks}"
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = "${module.vpc.database_subnets}"
}

output "database_subnets_cidr_blocks" {
  description = "List of cidr_blocks of database subnets"
  value       = "${module.vpc.database_subnets_cidr_blocks}"
}

output "database_subnet_group" {
  description = "ID of database subnet group"
  value       = "${module.vpc.database_subnet_group}"
}

output "redshift_subnets" {
  description = "List of IDs of redshift subnets"
  value       = "${module.vpc.redshift_subnets}"
}

output "redshift_subnets_cidr_blocks" {
  description = "List of cidr_blocks of redshift subnets"
  value       = "${module.vpc.redshift_subnets_cidr_blocks}"
}

output "redshift_subnet_group" {
  description = "ID of redshift subnet group"
  value       = "${module.vpc.redshift_subnet_group}"
}

output "elasticache_subnets" {
  description = "List of IDs of elasticache subnets"
  value       = "${module.vpc.elasticache_subnets}"
}

output "elasticache_subnets_cidr_blocks" {
  description = "List of cidr_blocks of elasticache subnets"
  value       = "${module.vpc.elasticache_subnets_cidr_blocks}"
}

output "intra_subnets" {
  description = "List of IDs of intra subnets"
  value       = "${module.vpc.intra_subnets}"
}

output "intra_subnets_cidr_blocks" {
  description = "List of cidr_blocks of intra subnets"
  value       = "${module.vpc.intra_subnets_cidr_blocks}"
}

output "elasticache_subnet_group" {
  description = "ID of elasticache subnet group"
  value       = "${module.vpc.elasticache_subnet_group}"
}

output "elasticache_subnet_group_name" {
  description = "Name of elasticache subnet group"
  value       = "${module.vpc.elasticache_subnet_group_name}"
}

output "public_route_table_ids" {
  description = "List of IDs of public route tables"
  value       = "${module.vpc.public_route_table_ids}"
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = "${module.vpc.private_route_table_ids}"
}

output "database_route_table_ids" {
  description = "List of IDs of database route tables"
  value       = "${module.vpc.database_route_table_ids}"
}

output "redshift_route_table_ids" {
  description = "List of IDs of redshift route tables"
  value       = "${module.vpc.redshift_route_table_ids}"
}

output "elasticache_route_table_ids" {
  description = "List of IDs of elasticache route tables"
  value       = "${module.vpc.elasticache_route_table_ids}"
}

output "intra_route_table_ids" {
  description = "List of IDs of intra route tables"
  value       = "${module.vpc.intra_route_table_ids}"
}

output "nat_ids" {
  description = "List of allocation ID of Elastic IPs created for AWS NAT Gateway"
  value       = "${module.vpc.nat_ids}"
}

output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = "${module.vpc.nat_public_ips}"
}

output "natgw_ids" {
  description = "List of NAT Gateway IDs"
  value       = "${module.vpc.natgw_ids}"
}

output "igw_id" {
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

output "vgw_id" {
  description = "The ID of the VPN Gateway"
  value       = "${module.vpc.vgw_id}"
}

output "vpc_endpoint_dynamodb_pl_id" {
  description = "The prefix list for the DynamoDB VPC endpoint."
  value       = "${module.vpc.vpc_endpoint_dynamodb_pl_id}"
}

output "default_vpc_id" {
  description = "The ID of the VPC"
  value       = "${module.vpc.default_vpc_id}"
}

output "default_vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = "${module.vpc.default_vpc_cidr_block}"
}

output "default_vpc_default_security_group_id" {
  description = "The ID of the security group created by default on VPC creation"
  value       = "${module.vpc.default_vpc_default_security_group_id}"
}

output "default_vpc_default_network_acl_id" {
  description = "The ID of the default network ACL"
  value       = "${module.vpc.default_vpc_default_network_acl_id}"
}

output "default_vpc_default_route_table_id" {
  description = "The ID of the default route table"
  value       = "${module.vpc.default_vpc_default_route_table_id}"
}

output "default_vpc_instance_tenancy" {
  description = "Tenancy of instances spin up within VPC"
  value       = "${module.vpc.default_vpc_instance_tenancy}"
}

output "default_vpc_enable_dns_support" {
  description = "Whether or not the VPC has DNS support"
  value       = "${module.vpc.default_vpc_enable_dns_support}"
}

output "default_vpc_enable_dns_hostnames" {
  description = "Whether or not the VPC has DNS hostname support"
  value       = "${module.vpc.default_vpc_enable_dns_hostnames}"
}

//output "default_vpc_enable_classiclink" {
//  description = "Whether or not the VPC has Classiclink enabled"
//  value       = "${element(concat(aws_default_vpc.this.*.enable_classiclink, list("")), 0)}"
//}

output "default_vpc_main_route_table_id" {
  description = "The ID of the main route table associated with this VPC"
  value       = "${module.vpc.default_vpc_main_route_table_id}"
}

//output "default_vpc_ipv6_association_id" {
//  description = "The association ID for the IPv6 CIDR block"
//  value       = "${element(concat(aws_default_vpc.this.*.ipv6_association_id, list("")), 0)}"
//}
//
//output "default_vpc_ipv6_cidr_block" {
//  description = "The IPv6 CIDR block"
//  value       = "${element(concat(aws_default_vpc.this.*.ipv6_cidr_block, list("")), 0)}"
//}

