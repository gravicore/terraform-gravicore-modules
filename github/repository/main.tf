# ----------------------------------------------------------------------------------------------------------------------
# Resources
# ----------------------------------------------------------------------------------------------------------------------

resource "github_repository" "default" {
  count = var.create ? 1 : 0
  name  = var.project_type == "" ? join(var.delimiter, [var.namespace, var.repo_name]) : join(var.delimiter, [var.namespace, var.repo_name, var.project_type])

  description                             = var.repository_description
  homepage_url                            = var.homepage_url
  visibility                              = var.visibility
  has_issues                              = var.has_issues
  has_projects                            = var.has_projects
  has_wiki                                = var.has_wiki
  is_template                             = var.is_template
  allow_merge_commit                      = var.allow_merge_commit
  allow_squash_merge                      = var.allow_squash_merge
  allow_rebase_merge                      = var.allow_rebase_merge
  allow_auto_merge                        = var.allow_auto_merge
  delete_branch_on_merge                  = var.delete_branch_on_merge
  has_downloads                           = var.has_downloads
  auto_init                               = var.auto_init
  gitignore_template                      = var.gitignore_template
  license_template                        = var.license_template
  archived                                = var.archived
  archive_on_destroy                      = var.archive_on_destroy
  topics                                  = var.topics
  vulnerability_alerts                    = var.vulnerability_alerts
  ignore_vulnerability_alerts_during_read = var.ignore_vulnerability_alerts_during_read
}

# data "github_user" "default" {
#   for_each = toset(local.users_lists)
#   username = each.key
# }

# data "github_team" "default" {
#   for_each = toset(local.teams_list)
#   slug     = each.key
# }

resource "github_repository_environment" "default" {
  for_each = var.create ? var.environments : {}

  environment = each.key
  repository  = github_repository.default[0].name
  # reviewers {
  #   users = [for user in lookup(each.value, "reviewers_users", []) : data.github_user.default[user].id]
  #   teams = [for team in lookup(each.value, "reviewers_teams", []) : data.github_team.default[team].id]
  # }
  deployment_branch_policy {
    protected_branches     = lookup(each.value, "protected_branches", true)
    custom_branch_policies = lookup(each.value, "custom_branch_policies", false)
  }
}

# resource "github_team_repository" "default" {
#   for_each   = var.create ? var.access_teams : {}
#   team_id    = each.key
#   repository = github_repository.default[0].name
#   permission = each.value
# }

resource "github_branch_protection" "default" {
  count                           = var.create && var.enable_main_branch_protection ? 1 : 0
  repository_id                   = github_repository.default[0].name
  pattern                         = var.pattern
  enforce_admins                  = var.enforce_admins
  require_signed_commits          = var.require_signed_commits
  required_linear_history         = var.required_linear_history
  require_conversation_resolution = var.require_conversation_resolution
  required_status_checks {
    strict   = var.strict
    contexts = var.contexts
  }
  required_pull_request_reviews {
    dismiss_stale_reviews           = var.dismiss_stale_reviews
    restrict_dismissals             = var.restrict_dismissals
    dismissal_restrictions          = var.dismissal_restrictions
    pull_request_bypassers          = var.pull_request_bypassers
    require_code_owner_reviews      = var.require_code_owner_reviews
    required_approving_review_count = var.required_approving_review_count
  }
  push_restrictions   = var.push_restrictions
  allows_deletions    = var.allows_deletions
  allows_force_pushes = var.allows_force_pushes
}

# ----------------------------------------------------------------------------------------------------------------------
# Locals
# ----------------------------------------------------------------------------------------------------------------------

locals {

  environment_prefix = coalesce(var.environment_prefix, join(var.delimiter, compact([var.namespace, var.environment])))
  stage_prefix       = coalesce(var.stage_prefix, join(var.delimiter, compact([local.environment_prefix, var.stage])))
  module_prefix      = coalesce(var.module_prefix, join(var.delimiter, compact([local.stage_prefix, var.name])))

  business_tags = {
    namespace          = var.namespace
    environment        = var.environment
    environment_prefix = local.environment_prefix
  }
  technical_tags = {
    stage      = var.stage
    module     = var.name
    repository = var.repository
  }
  automation_tags = {
    terraform_module = var.terraform_module
    stage_prefix     = local.stage_prefix
    module_prefix    = local.module_prefix
  }
  security_tags = {}

  tags = merge(
    local.business_tags,
    local.technical_tags,
    local.automation_tags,
    local.security_tags,
    var.tags
  )
}
