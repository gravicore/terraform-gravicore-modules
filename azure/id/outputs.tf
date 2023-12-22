output "user_assigned_identity_info" {
  description = "Map of User Assigned Managed Identity names to their IDs."

  value = {
    for key, resource in azurerm_user_assigned_identity.default : key => {
      id           = resource.id
      client_id    = resource.client_id
      principal_id = resource.principal_id
    }
  }
}

