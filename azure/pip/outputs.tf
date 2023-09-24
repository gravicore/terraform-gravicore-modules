output "public_ip_mappings" {

  value = {
    for key, resource in azurerm_public_ip.default  : key => {
      name = resource.ip_address
      id   = resource.id
    }
  }
}