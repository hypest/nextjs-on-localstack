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

variable "localstack_endpoint" {
  description = "LocalStack endpoint URL"
  type        = string
  default     = "http://localhost:4566"
}

variable "registry_endpoint" {
  description = "Docker registry endpoint (e.g., localhost:5001)"
  type        = string
  default     = "localhost:5001"
}

variable "image_tag" {
  description = "Docker image tag for backend API"
  type        = string
  default     = "latest"
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
