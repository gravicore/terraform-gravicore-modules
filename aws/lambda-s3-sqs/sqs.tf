# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES / LOCALS / REMOTE STATE
# ----------------------------------------------------------------------------------------------------------------------

variable "delay_seconds" {
  description = "The time delay for messages"
  type        = number
}

variable "max_message_size" {
  description = "The maximum size of a message"
  type        = number
}

variable "message_retention_seconds" {
  description = "The retention period for messages"
  type        = number
}

variable "receive_wait_time_seconds" {
  description = "The wait time for receiving messages"
  type        = number
}

variable "is_fifo" {
  description = "Whether the queue is FIFO"
  type        = bool
}


# ----------------------------------------------------------------------------------------------------------------------
# MODULES / RESOURCES
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_sqs_queue" "default" {
  name                      = "${local.module_prefix}-sqs-queue"
  delay_seconds             = var.delay_seconds
  fifo_queue                = var.is_fifo
  max_message_size          = var.max_message_size
  message_retention_seconds = var.message_retention_seconds
  receive_wait_time_seconds = var.receive_wait_time_seconds
  tags                      = local.tags
}


# ----------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ----------------------------------------------------------------------------------------------------------------------

output "sqs_queue_arn" {
  value = aws_sqs_queue.default.arn
}

output "sqs_queue_id" {
  value = aws_sqs_queue.default.id
}
