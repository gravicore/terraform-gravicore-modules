resource "aviatrix_account" "current" {
  account_name       = "${local.stage_prefix}"
  cloud_type         = "${var.aviatrix_controller_cloud_type}"
  aws_account_number = "${var.account_id}"
  aws_iam            = "true"
  aws_role_ec2       = "arn:aws:iam::${var.account_id}:role/aviatrix-role-ec2"
  aws_role_app       = "arn:aws:iam::${var.account_id}:role/aviatrix-role-app"
}

# Launch a gateway with these parameters:
# cloud_type - Enter 1 for AWS. Only AWS is currently supported.
# account_name - Aviatrix account name to launch GW with.
# gw_name - Name of gateway.
# vpc_id - AWS VPC ID.
# vpc_reg - AWS VPC region.
# vpc_size - Gateway instance size
# vpc_net - VPC subnet CIDR where you want to launch GW instance


# resource "aviatrix_gateway" "default" {
#   account_name = "${join("-", list(var.namespace, var.environment, var.stage))}"
#   cloud_type   = "${var.aviatrix_controller_cloud_type}"
#   gw_name      = "${local.name_prefix}-gw"
#   vpc_id       = "${data.terraform_remote_state.vpc.vpc_id}"
#   vpc_reg      = "${var.aws_region}"
#   vpc_net      = "${var.vpc_cidr_block}"
#   vpc_size     = "${var.aviatrix_gateway_size}"
# }

