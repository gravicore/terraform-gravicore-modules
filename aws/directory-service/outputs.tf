output "directory_id" {
  value = "${aws_directory_service_directory.default.id}"
}

output "ad_access_url" {
  value = "${aws_directory_service_directory.default.access_url}"
}

output "dns_ip_addresses" {
  value = "${aws_directory_service_directory.default.dns_ip_addresses}"
}

output "ad_security_group_id" {
  value = "${aws_directory_service_directory.default.security_group_id}"
}

output "domain_name" {
  value = "${aws_directory_service_directory.default.name}"
}
