output "key_name" {
  value = module.ssh_key_pair.key_name
}

output "public_key" {
  value = module.ssh_key_pair.public_key
}

output "private_ip" {
  value = module.aviatrix_controller.private_ip
}

output "public_ip" {
  value = module.aviatrix_controller.public_ip
}

