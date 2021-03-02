# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

############################################
#######Variable for Schema Attributes#######

###NOTE When defining an attribute_data_type of String or Number, the respective attribute constraints configuration block (e.g string_attribute_constraints or number_attribute_contraints) is required to prevent recreation of the Terraform resource. This requirement is true for both standard (e.g. name, email) and custom schema attributes.

variable attribute_data_type {
  type        = string
  description = "The attribute data type. Must be one of Boolean, Number, String, DateTime."
  default     = ""
}


variable developer_only_attribute {
  type        = bool
  description = "Specifies whether the attribute type is developer only"
  default     = null
}

variable mutable {
  type        = bool
  description = "Specifies whether the attribute can be changed once it has been created"
  default     = true
}

variable attribute_name {
  type        = string
  description = "The name of the attribute"
  default     = ""
}

variable number_attribute_constraints {
  type        = string
  description = "Specifies the constraints for an attribute of the number type."
  default     = ""
}

variable required {
  type        = bool
  description = "Specifies whether a user pool attribute is required. If the attribute is required and the user does not provide a value, registration or sign-in will fail"
  default     = false
}

variable string_attribute_constraints {
  type        = list
  description = "Specifies the constraints for an attribute of the string type"
  default     = []
}

#Variable Number Attribute Constraints (inside of schema)

variable max_value {
  type        = number
  description = "The maximum value of an attribute that is of the number data type"
  default     = null
}

variable min_value {
  type        = number
  description = "The minimum value of an attribute that is of the number data type"
  default     = null
}

#Variable String Attribute Constraints (inside of schema)

variable max_length {
  type        = number
  description = "The maximum length of an attribute value of the string type"
  default     = null
}

variable min_length {
  type        = number
  description = "The minimum length of an attribute value of the string type"
  default     = null
}

