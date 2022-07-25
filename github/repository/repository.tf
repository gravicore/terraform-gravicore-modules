# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "project_type" {
  type        = string
  default     = "infra"
  description = "(Optional) The Type of repository used (i.e. infra, services, security, etc.)"
}

variable "repo_name" {
  type        = string
  default     = ""
  descirption = ""
}

variable "repository_description" {
  type        = string
  default     = ""
  description = "(Optional) A description of the repository."
}

variable "homepage_url" {
  type        = string
  default     = null
  description = "(Optional) URL of a page describing the project."
}

variable "visibility" {
  type        = string
  default     = "private"
  description = "(Optional) Can be public or private. If your organization is associated with an enterprise account using GitHub Enterprise Cloud or GitHub Enterprise Server 2.20+, visibility can also be internal. The visibility parameter overrides the private parameter."
}

variable "has_issues" {
  type        = bool
  default     = false
  description = "(Optional) Set to true to enable the GitHub Issues features on the repository."
}

variable "has_projects" {
  type        = bool
  default     = false
  description = "(Optional) Set to true to enable the GitHub Projects features on the repository. Per the GitHub documentation when in an organization that has disabled repository projects it will default to false and will otherwise default to true. If you specify true when it has been disabled it will return an error."
}

variable "has_wiki" {
  type        = bool
  default     = false
  description = "(Optional) Set to true to enable the GitHub Wiki features on the repository."
}

variable "is_template" {
  type        = bool
  default     = false
  description = "(Optional) Set to true to tell GitHub that this is a template repository."
}

variable "allow_merge_commit" {
  type        = bool
  default     = true
  description = "(Optional) Set to false to disable merge commits on the repository."
}

variable "allow_squash_merge" {
  type        = bool
  default     = false
  description = "(Optional) Set to false to disable squash merges on the repository."
}

variable "allow_rebase_merge" {
  type        = bool
  default     = true
  description = "(Optional) Set to false to disable rebase merges on the repository."
}

variable "allow_auto_merge" {
  type        = bool
  default     = false
  description = "(Optional) Set to true to allow auto-merging pull requests on the repository."
}

variable "delete_branch_on_merge" {
  type        = bool
  default     = true
  description = "(Optional) Automatically delete head branch after a pull request is merged. Defaults to false."
}

variable "has_downloads" {
  type        = bool
  default     = false
  description = "(Optional) Set to true to enable the (deprecated) downloads features on the repository."
}

variable "auto_init" {
  type        = bool
  default     = false
  description = "(Optional) Set to true to produce an initial commit in the repository."
}

variable "gitignore_template" {
  type        = string
  default     = null
  description = "(Optional) Use the name of the template without the extension. For example, 'Haskell'"
}

variable "license_template" {
  type        = string
  default     = null
  description = "(Optional) Use the name of the template without the extension. For example, 'mit''mp or l-2.0.'"
}

variable "archived" {
  type        = bool
  default     = false
  description = "(Optional) Specifies if the repository should be archived. Defaults to false. NOTE Currently, the API does not support unarchiving."
}

variable "archive_on_destroy" {
  type        = bool
  default     = true
  description = "(Optional) Set to true to archive the repository instead of deleting on destroy."
}

variable "topics" {
  type        = list(any)
  default     = []
  description = "(Optional) The list of topics of the repository."
}

variable "vulnerability_alerts" {
  type        = bool
  default     = false
  description = "(Optional) - Set to true to enable security alerts for vulnerable dependencies. Enabling requires alerts to be enabled on the owner level. (Note for importing: GitHub enables the alerts on public repos but disables them on private repos by default.) See https://help.github.com/en/github/managing-security-vulnerabilities/about-security-alerts-for-vulnerable-dependencies for details. Note that vulnerability alerts have not been successfully tested on any GitHub Enterprise instance and may be unavailable in those settings."
}

variable "ignore_vulnerability_alerts_during_read" {
  type        = bool
  default     = true
  description = "(Optional) - Set to true to not call the vulnerability alerts endpoint so the resource can also be used without admin permissions during read."
}

variable "environments" {
  type = map(any)
  default = {
    test = {
      reviewers_teams        = []
      reviewers_users        = []
      protected_branches     = false
      custom_branch_policies = false
    },
    stg = {
      reviewers_teams        = []
      reviewers_users        = []
      protected_branches     = false
      custom_branch_policies = false
    },
    prd = {
      reviewers_teams        = []
      reviewers_users        = []
      protected_branches     = true
      custom_branch_policies = false
    }
  }
  description = "(Optional) - The list of environments to be created on the repository"
}

locals {
  users_lists = flatten([for env in var.environments : lookup(env, "reviewers_users", [""])])
  teams_list  = flatten([for env in var.environments : lookup(env, "reviewers_teams", [""])])
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "github_repository" "default" {
  name = var.project_type == "" ? join(var.delimiter, [var.namespace, var.repo_name]) : join(var.delimiter, [var.namespace, var.repo_name, var.project_type])

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

data "github_user" "default" {
  for_each = toset(local.users_lists)
  username = each.key
}

data "github_team" "default" {
  for_each = toset(local.teams_list)
  slug     = each.key
}

resource "github_repository_environment" "default" {
  for_each    = var.environments
  environment = each.key
  repository  = github_repository.default.name
  reviewers {
    users = [for user in lookup(each.value, "reviewers_users", null) : data.github_user.default[user].id]
    teams = [for team in lookup(each.value, "reviewers_teams", null) : data.github_team.default[team].id]
  }
  deployment_branch_policy {
    protected_branches     = lookup(each.value, "protected_branches", false)
    custom_branch_policies = lookup(each.value, "custom_branch_policies", false)
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------------------------------------------------
