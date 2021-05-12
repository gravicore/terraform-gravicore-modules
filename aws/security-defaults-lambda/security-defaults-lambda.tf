# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "lambda_function_names" {
  type        = list(string)
  default     = []
  description = "lambda_function_names to apply default VPCs to"
}

variable "subnet_ids" {
  type        = list(string)
  default     = []
  description = "subnet_ids to apply to lambda functions"
}

variable "security_group_ids" {
  type        = list(string)
  default     = []
  description = "security_group_ids to apply to lambda functions"
}

# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "null_resource" "update_lambda_functions" {
  count = length(var.lambda_function_names)

  triggers = {
    script_hash = "${sha256(file("${path.module}/scripts/update-functions.py"))}"
  }

  provisioner "local-exec" {
    command = "python ./scripts/update-functions.py ${var.lambda_function_names[count.index]} ${join(",", var.subnet_ids)} ${join(",", var.security_group_ids)}"
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# Outputs
# ----------------------------------------------------------------------------------------------------------------------