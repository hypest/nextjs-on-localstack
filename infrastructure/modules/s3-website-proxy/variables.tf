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
