output "log_analytics_workspaces" {
  value = {
    for key, ws in azurerm_log_analytics_workspace.default :
    key => {
      id           = ws.id,
      workspace_id = ws.workspace_id,
      name         = ws.name
    }
  }
}


output "log_analytics_solutions" {
  value = {
    for key, solution in azurerm_log_analytics_solution.default :
    key => {
      id            = solution.id,
      solution_name = solution.solution_name,
    }
  }
}

