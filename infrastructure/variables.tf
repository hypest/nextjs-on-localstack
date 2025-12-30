variable "infra_name" {
  description = "Name of the infrastructure project"
  type        = string
  validation {
    condition     = length(var.infra_name) > 0
    error_message = "Infrastructure name cannot be empty."
  }
}

variable "environment" {
  description = "Environment name (e.g., prod, staging, feature/mybranch) - REQUIRED"
  type        = string
}

variable "bucket_base_name" {
  description = "Base name for S3 bucket (e.g., hello-nextjs)"
  type        = string
  validation {
    condition     = length(var.bucket_base_name) > 0
    error_message = "Bucket base name cannot be empty."
  }
}

variable "localstack_endpoint" {
  description = "LocalStack endpoint URL"
  type        = string
  default     = "http://localhost:4566"
}

variable "api_port" {
  description = "API port for backend service"
  type        = number
  default     = 3001
}

variable "api_internal_port" {
  description = "Internal API port for container-to-container communication"
  type        = number
  default     = 3001
}

variable "proxy_port" {
  description = "Port for S3 website proxy (for Codespaces compatibility)"
  type        = number
  default     = 8888
}
