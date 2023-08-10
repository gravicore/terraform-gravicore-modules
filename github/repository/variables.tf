
# ----------------------------------------------------------------------------------------------------------------------
# Module Standard Variables
# ----------------------------------------------------------------------------------------------------------------------

variable "name" {
  type        = string
  default     = ""
  description = "The name of the module"
}

variable "terraform_module" {
  type        = string
  default     = "gravicore/terraform-gravicore-modules/github/repository"
  description = "The owner and name of the Terraform module"
}

variable "create" {
  type        = bool
  default     = true
  description = "Set to false to prevent the module from creating any resources"
}

# ----------------------------------------------------------------------------------------------------------------------
# Platform Standard Variables
# ----------------------------------------------------------------------------------------------------------------------

# Recommended

variable "namespace" {
  type        = string
  default     = ""
  description = "Namespace, which could be your organization abbreviation, client name, etc. (e.g. Gravicore 'grv', HashiCorp 'hc')"
}

variable "environment" {
  type        = string
  default     = ""
  description = "The isolated environment the module is associated with (e.g. Shared Services `shared`, Application `app`)"
}

variable "stage" {
  type        = string
  default     = ""
  description = "The development stage (i.e. `dev`, `stg`, `prd`)"
}

variable "repository" {
  type        = string
  default     = ""
  description = "The repository where the code referencing the module is stored"
}

# Optional

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional map of tags (e.g. business_unit, cost_center)"
}

variable "desc_prefix" {
  type        = string
  default     = "Gravicore:"
  description = "The prefix to add to any descriptions attached to resources"
}

variable "environment_prefix" {
  type        = string
  default     = ""
  description = "Concatenation of `namespace` and `environment`"
}

variable "stage_prefix" {
  type        = string
  default     = ""
  description = "Concatenation of `namespace`, `environment` and `stage`"
}

variable "module_prefix" {
  type        = string
  default     = ""
  description = "Concatenation of `namespace`, `environment`, `stage` and `name`"
}

variable "delimiter" {
  type        = string
  default     = "-"
  description = "Delimiter to be used between `namespace`, `environment`, `stage`, `name`"
}

# ----------------------------------------------------------------------------------------------------------------------
# Module Variables
# ----------------------------------------------------------------------------------------------------------------------

variable "project_type" {
  type        = string
  default     = "infra"
  description = "(Optional) The Type of repository used (i.e. infra, services, security, etc.)"
}

variable "repo_name" {
  type        = string
  default     = ""
  description = ""
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

variable "has_discussions" {
  type        = bool
  default     = false
  description = "(Optional) Set to true to enable GitHub Discussions on the repository. Defaults to false."
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

variable "squash_merge_commit_title" {
  type        = string
  default     = null
  description = "(Optional) Can be PR_TITLE or COMMIT_OR_PR_TITLE for a default squash merge commit title."
}

variable "squash_merge_commit_message" {
  type        = string
  default     = null
  description = "(Optional) Can be PR_BODY, COMMIT_MESSAGES, or BLANK for a default squash merge commit message."
}

variable "merge_commit_title" {
  type        = string
  default     = null
  description = "(Optional) Can be PR_TITLE or MERGE_MESSAGE for a default merge commit title."
}

variable "merge_commit_message" {
  type        = string
  default     = null
  description = "(Optional) Can be PR_BODY, PR_TITLE, or BLANK for a default merge commit message."
}

variable "delete_branch_on_merge" {
  type        = bool
  default     = true
  description = "(Optional) Automatically delete head branch after a pull request is merged. Defaults to false."
}

variable "has_downloads" {
  type        = bool
  default     = true
  description = "(Optional) Set to true to enable the (deprecated) downloads features on the repository."
}

variable "auto_init" {
  type        = bool
  default     = true
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
  default     = true
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
    dev = {
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
  users_lists = flatten([for env in var.environments : lookup(env, "reviewers_users", [])])
  teams_list  = flatten([for env in var.environments : lookup(env, "reviewers_teams", [])])
}

variable "access_teams" {
  type        = map(any)
  default     = {}
  description = "Map of teams to be given access to the repository and their permission level"
}

variable "pattern" {
  type        = string
  default     = "main"
  description = "(Required) Identifies the protection rule pattern. Branch name that rules apply to."
}

variable "enforce_admins" {
  type        = bool
  default     = true
  description = "(Optional) Boolean, setting this to true enforces status checks for repository administrators."
}

variable "require_signed_commits" {
  type        = bool
  default     = false
  description = "(Optional) - Set to true to not call the vulnerability alerts endpoint so the resource can also be used without admin permissions during read."
}

variable "required_linear_history" {
  type        = bool
  default     = false
  description = "(Optional) Boolean, setting this to true enforces a linear commit Git history, which prevents anyone from pushing merge commits to a branch"
}

variable "require_conversation_resolution" {
  type        = bool
  default     = true
  description = "(Optional) Boolean, setting this to true requires all conversations on code must be resolved before a pull request can be merged."
}

variable "required_status_checks" {
  type        = bool
  default     = false
  description = "(Optional) Enforce restrictions for required status checks."
}

variable "required_pull_request_reviews" {
  type        = bool
  default     = true
  description = "(Optional) Enforce restrictions for pull request reviews."
}

variable "push_restrictions" {
  type        = list(any)
  default     = null
  description = "(Optional) The list of actor IDs that may push to the branch."
}

variable "allows_deletions" {
  type        = bool
  default     = false
  description = "(Optional) Boolean, setting this to true to allow the branch to be deleted."
}

variable "allows_force_pushes" {
  type        = bool
  default     = false
  description = "(Optional) Boolean, setting this to true to allow force pushes on the branch."
}

variable "blocks_creations" {
  type        = bool
  default     = true
  description = "(Optional) Boolean, setting this to true to block creating the branch."
}

variable "strict" {
  type        = bool
  default     = true
  description = "(Optional) Require branches to be up to date before merging. Defaults to false."
}

variable "contexts" {
  type        = list(any)
  default     = null
  description = "(Optional) The list of status checks to require in order to merge into this branch. No status checks are required by default."
}

variable "dismiss_stale_reviews" {
  type        = bool
  default     = true
  description = "(Optional) Dismiss approved reviews automatically when a new commit is pushed. Defaults to false."
}

variable "restrict_dismissals" {
  type        = bool
  default     = false
  description = "(Optional) Restrict pull request review dismissals."
}

variable "dismissal_restrictions" {
  type        = list(any)
  default     = null
  description = "(Optional) The list of actor IDs with dismissal access. If not empty, restrict_dismissals is ignored."
}

variable "pull_request_bypassers" {
  type        = list(any)
  default     = null
  description = "(Optional) The list of actor IDs that are allowed to bypass pull request requirements."
}

variable "require_code_owner_reviews" {
  type        = bool
  default     = true
  description = "(Optional) Require an approved review in pull requests including files with a designated code owner. Defaults to false."
}

variable "required_approving_review_count" {
  type        = number
  default     = 1
  description = "(Optional) Require x number of approvals to satisfy branch protection requirements. If this is specified it must be a number between 0-6. This requirement matches GitHub's API, see https://developer.github.com/v3/repos/branches/#parameters-1 for more information."
}

variable "enable_main_branch_protection" {
  type        = bool
  default     = true
  description = "(Optional) Boolean, setting this to true enables branch protection for the main branch."
}

variable "enable_protections" {
  type        = bool
  default     = true
  description = "(Optional) Boolean, setting this to true enables protections for the repository."
}
