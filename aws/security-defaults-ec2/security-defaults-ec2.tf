# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "instance_ids" {
  type        = list(string)
  default     = []
  description = "Instance IDs to apply default security settings to"
}

variable "enable_http_tokens" {
  type        = bool
  description = "HTTP Tokens required for Meta Data Options?"
  default     = false
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "null_resource" "update_ec2_instances" {
  count = length(var.instance_ids)

  triggers = {
    enable_http_tokens        = var.enable_http_tokens
    script_hash                 = "${sha256(file("${path.module}/scripts/update-ec2-instances.py"))}"
  }

  provisioner "local-exec" {
    command = "python ./scripts/update-ec2-instances.py ${var.instance_ids[count.index]} ${var.enable_http_tokens}"
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------------------------------------------------