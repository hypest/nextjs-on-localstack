variable "environment" {
  description = "Environment name (e.g., prod, staging, feature-branch)"
  type        = string
}

variable "infra_name" {
  description = "Infrastructure name for resource naming"
  type        = string
  default     = "s3-website-proxy"
}

variable "proxy_port" {
  description = "Port for the S3 website proxy"
  type        = number
  default     = 8888
}

variable "bucket_name" {
  description = "S3 bucket name to proxy to"
  type        = string
}

variable "backend_container_name" {
  description = "Name of the backend API container"
  type        = string
}

variable "api_gateway_url" {
  description = "URL of the API Gateway (internal to LocalStack)"
  type        = string
}
