# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "teams" {
  type        = map(any)
  default     = {}
  description = <<EOF
  A list of Github Teams, uses the format:
  team_name = {
    description    = (Optional) A description of the team                           (String)
    privacy        = (Optional) The level of privacy for the team                   (String, "secret" or "closed", defaults to "secret")
    parent_team_id = (Optional) The ID of the parent team, if this is a nested team (String)
    members        = {
      username<(Required) The user to add to the team> = role<(Optional) The role of the user within the team. Must be one of member or maintainer. Defaults to member>
    }
  }
  EOF
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "github_team" "default" {
  for_each       = var.teams
  name           = each.key
  description    = each.value.description
  privacy        = each.value.privacy
  parent_team_id = each.value.parent_team_id
}

resource "github_team_members" "default" {
  for_each = var.teams

  team_id = github_team.default[each.key].id

  dynamic "members" {
    for_each = lookup(each.value, "members", null)

    content {
      username = members.key
      role     = members.value
    }
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------------------------------------------------
