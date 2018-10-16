resource "aws_directory_service_directory" "default" {
  name       = "${var.dns_zone_name}.${var.parent_domain_name}"
  password   = "${var.password}"
  edition    = "${var.edition}"
  type       = "${var.type}"
  alias      = "${module.common_label.id}"
  enable_sso = "${var.enable_sso}"
  short_name = "${var.directory_services_short_name}"

  vpc_settings {
    vpc_id     = "${data.terraform_remote_state.vpc.vpc_id}"
    subnet_ids = ["${data.terraform_remote_state.vpc.private_subnets}"]
  }

  tags = "${local.default_tags}"
}

resource "aws_vpc_dhcp_options" "default" {
  domain_name          = "${aws_directory_service_directory.default.name}"
  domain_name_servers  = ["${aws_directory_service_directory.default.dns_ip_addresses}"]
  ntp_servers          = ["${aws_directory_service_directory.default.dns_ip_addresses}"]
  netbios_name_servers = ["${aws_directory_service_directory.default.dns_ip_addresses}"]
  netbios_node_type    = "${var.netbios_node_type}"
  tags                 = "${local.default_tags}"
}

resource "aws_vpc_dhcp_options_association" "default" {
  vpc_id          = "${data.terraform_remote_state.vpc.vpc_id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.default.id}"
}
