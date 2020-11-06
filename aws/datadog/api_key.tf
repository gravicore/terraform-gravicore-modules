# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "datadog_api_key" {
  description = "Datadog API key. This can also be set via the DATADOG_API_KEY environment variable."
}

variable "datadog_app_key" {
  description = "Datadog APP key. This can also be set via the DATADOG_APP_KEY environment variable."
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "datadog_api_key" {
  name        = "${local.module_prefix}-api-key"
  description = "Encrypted Datadog API Key"
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "datadog_api_key" {
  secret_id     = aws_secretsmanager_secret.datadog_api_key.id
  secret_string = var.datadog_api_key
}

# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "datadog_api_key_arn" {
  value = aws_secretsmanager_secret.datadog_api_key.arn
}
