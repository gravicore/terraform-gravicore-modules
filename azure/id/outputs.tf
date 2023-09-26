output "user_assigned_identity_info" {
  description = "Map of User Assigned Managed Identity names to their IDs."

  value = {
    for key, resource in azurerm_user_assigned_identity.default : key => {
      client_id    = resource.client_id
      id           = resource.id
      principal_id = resource.principal_id
    }
  }
}

