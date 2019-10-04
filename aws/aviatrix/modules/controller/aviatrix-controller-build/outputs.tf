output "private_ip" {
  value = aws_instance.aviatrixcontroller[0].private_ip
}

output "public_ip" {
  value = aws_eip.controller_eip[0].public_ip
}

