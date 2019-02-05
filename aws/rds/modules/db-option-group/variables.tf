variable "create" {
  description = "Whether to create this resource or not?"
  default     = true
}

variable "name_prefix" {
  description = "Creates a unique name beginning with the specified prefix"
}

variable "identifier" {
  description = "The identifier of the resource"
  default     = "default rds"
}

variable "option_group_description" {
  description = "The description of the option group"
  default     = ""
}

variable "engine_name" {
  description = "Specifies the name of the engine that this option group should be associated with"
}

variable "major_engine_version" {
  description = "Specifies the major version of the engine that this option group should be associated with"
}

variable "options" {
  type        = "list"
  description = "A list of Options to apply"
  default     = []
}

variable "tags" {
  type        = "map"
  description = "A mapping of tags to assign to the resource"
  default     = {}
}

variable "aws_region" {
  default = "us-east-1"
}

variable "kms_key_id" {
  description = "The ARN for the KMS encryption key. If creating an encrypted replica, set this to the destination KMS ARN. If storage_encrypted is set to true and kms_key_id is not specified the default KMS key created in your account will be used"
  default     = ""
}
