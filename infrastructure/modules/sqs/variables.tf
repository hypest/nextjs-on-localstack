variable "queue_name" {
  description = "Name of the main SQS queue"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "infra_name" {
  description = "Infrastructure name for tags"
  type        = string
}
