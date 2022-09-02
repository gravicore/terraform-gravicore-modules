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

variable "externally_managed_teams" {
  type        = bool
  default     = false
  description = "A flag to set that will determine wether teams are managed through an external source (such as Okta)."
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "github_team" "default" {
  for_each = var.create && var.externally_managed_teams ? var.teams : {}
  # TODO: Add variable driven names
  name           = each.key
  description    = lookup(each.value, "description", null)
  privacy        = lookup(each.value, "privacy", null)
  parent_team_id = lookup(each.value, "parent_team_id", null)
}

resource "github_team_members" "default" {
  for_each = var.create && var.externally_managed_teams != true ? var.teams : {}

  team_id = github_team.default[each.key].id
  # TODO: Test adding/removing users manually, maybe lifecycle ignore change
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
