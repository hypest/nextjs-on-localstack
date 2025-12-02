variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "devcontainer-localstack"
}

variable "environment" {
  description = "Environment name (e.g., prod, staging, feature/mybranch) - REQUIRED"
  type        = string
}

variable "bucket_base_name" {
  description = "Base name for S3 bucket (e.g., hello-nextjs)"
  type        = string
  default     = "hello-nextjs"
}
