# ----------------------------------------------------------------------------------------------------------------------
# CAF resource
# ----------------------------------------------------------------------------------------------------------------------


module "azure_region" {
  source       = "git::https://github.com/gravicore/terraform-gravicore-modules.git//azure/regions?ref=0.46.0"
  azure_region = var.az_region
}


# ----------------------------------------------------------------------------------------------------------------------
# Policy resource
# ----------------------------------------------------------------------------------------------------------------------

resource "azurerm_policy_definition" "default" {
  for_each = var.create ? var.policy_definitions : {}

  name         = var.az_region
  display_name = each.value.display_name
  description  = each.value.description

  policy_type         = "Custom"
  mode                = each.value.policy_mode
  management_group_id = each.value.policy_mgmt_group_name

  policy_rule = each.value.policy_rule_content
  parameters  = each.value.policy_parameters_content
}

resource "azurerm_management_group_policy_assignment" "default" {
  for_each = var.create ? { for p_name, p_def in var.policy_assignments : p_name => p_def if lower(p_def.scope_type) == "management-group" } : {}

  name                 = each.key
  policy_definition_id = each.value.policy_definition_id != null ? each.value.policy_definition_id : azurerm_policy_definition.default[each.value.custom_policy_definition_key].id
  management_group_id  = each.value.scope_id

  location     = var.az_region
  display_name = each.value.display_name
  description  = each.value.description
  parameters   = each.value.parameters
  enforce      = each.value.enforce

  identity {
    type         = each.value.identity_type
    identity_ids = each.value.identity_ids
  }
}

resource "azurerm_subscription_policy_assignment" "default" {
  for_each = var.create ? { for p_name, p_def in var.policy_assignments : p_name => p_def if lower(p_def.scope_type) == "subscription" } : {}

  name                 = each.key
  policy_definition_id = each.value.policy_definition_id != null ? each.value.policy_definition_id : azurerm_policy_definition.default[each.value.custom_policy_definition_key].id
  subscription_id      = each.value.scope_id

  location     = var.az_region
  display_name = each.value.display_name
  description  = each.value.description
  parameters   = each.value.parameters
  enforce      = each.value.enforce

  identity {
    type         = each.value.identity_type
    identity_ids = each.value.identity_ids
  }
}

resource "azurerm_resource_group_policy_assignment" "default" {
  for_each = var.create ? { for p_name, p_def in var.policy_assignments : p_name => p_def if lower(p_def.scope_type) == "resource-group" } : {}

  name                 = each.key
  policy_definition_id = each.value.policy_definition_id != null ? each.value.policy_definition_id : azurerm_policy_definition.default[each.value.custom_policy_definition_key].id
  resource_group_id    = each.value.scope_id

  location     = var.az_region
  display_name = each.value.display_name
  description  = each.value.description
  parameters   = each.value.parameters
  enforce      = each.value.enforce

  identity {
    type         = each.value.identity_type
    identity_ids = each.value.identity_ids
  }
}

resource "azurerm_resource_policy_assignment" "default" {
  for_each = var.create ? { for p_name, p_def in var.policy_assignments : p_name => p_def if lower(p_def.scope_type) == "resource" } : {}

  name                 = each.key
  policy_definition_id = each.value.policy_definition_id != null ? each.value.policy_definition_id : azurerm_policy_definition.default[each.value.custom_policy_definition_key].id
  resource_id          = each.value.scope_id

  location     = var.az_region
  display_name = each.value.display_name
  description  = each.value.description
  parameters   = each.value.parameters
  enforce      = each.value.enforce

  identity {
    type         = each.value.identity_type
    identity_ids = each.value.identity_ids
  }
}


resource "azurerm_management_group_policy_remediation" "default" {
  for_each = var.create ? { for r_name, r_def in var.policy_assignment_remediation : r_name => r_def if lower(r_def.scope_type) == "management-group" } : {}

  name                 = each.value.name
  management_group_id  = each.value.scope_id
  policy_assignment_id = each.value.policy_assignment_id != null ? each.value.policy_assignment_id : azurerm_management_group_policy_assignment.default[each.value.policy_assignment_key].id
  location_filters     = each.value.location_filters
}

resource "azurerm_resource_group_policy_remediation" "default" {
  for_each = var.create ? { for r_name, r_def in var.policy_assignment_remediation : r_name => r_def if lower(r_def.scope_type) == "resource-group" } : {}

  name                 = each.value.name
  resource_group_id    = each.value.scope_id
  policy_assignment_id = each.value.policy_assignment_id != null ? each.value.policy_assignment_id : azurerm_resource_group_policy_assignment.default[each.value.policy_assignment_key].id
  location_filters     = each.value.location_filters
}

resource "azurerm_resource_policy_remediation" "default" {
  for_each = var.create ? { for r_name, r_def in var.policy_assignment_remediation : r_name => r_def if lower(r_def.scope_type) == "resource" } : {}

  name                 = each.value.name
  resource_id          = each.value.scope_id
  policy_assignment_id = each.value.policy_assignment_id != null ? each.value.policy_assignment_id : azurerm_resource_policy_assignment.default[each.value.policy_assignment_key].id
  location_filters     = each.value.location_filters
}

resource "azurerm_subscription_policy_remediation" "default" {
  for_each = var.create ? { for r_name, r_def in var.policy_assignment_remediation : r_name => r_def if lower(r_def.scope_type) == "subscription" } : {}

  name                 = each.value.name
  subscription_id      = each.value.scope_id
  policy_assignment_id = each.value.policy_assignment_id != null ? each.value.policy_assignment_id : azurerm_subscription_policy_assignment.default[each.value.policy_assignment_key].id
  location_filters     = each.value.location_filters
}

