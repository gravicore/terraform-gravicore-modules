# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "datadog_api_key" {
  description = "Datadog API key. This can also be set via the DATADOG_API_KEY environment variable."
}

variable "datadog_app_key" {
  description = "Datadog APP key. This can also be set via the DATADOG_APP_KEY environment variable."
}

variable datadog_api_key_recovery_window_in_days {
  description = "Number of days that AWS Secrets Manager waits before it can delete the secret. This value can be 0 to force deletion without recovery or range from 7 to 30 days. The default value is 30."
  default     = 0
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "datadog_api_key" {
  count       = var.create ? 1 : 0
  name        = "${local.module_prefix}-api-key"
  description = "Encrypted Datadog API Key"
  tags        = local.tags

  recovery_window_in_days = var.datadog_api_key_recovery_window_in_days
}

resource "aws_secretsmanager_secret_version" "datadog_api_key" {
  count = var.create ? 1 : 0

  secret_id     = concat(aws_secretsmanager_secret.datadog_api_key.*.id, [""])[0]
  secret_string = var.datadog_api_key
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "datadog_api_key_arn" {
  value = concat(aws_secretsmanager_secret.datadog_api_key.*.arn, [""])[0]
}
