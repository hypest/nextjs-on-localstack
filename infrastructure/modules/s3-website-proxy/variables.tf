variable "environment" {
  description = "Environment name (e.g., prod, staging, feature-branch)"
  type        = string
}

variable "infra_name" {
  description = "Infrastructure name for resource naming"
  type        = string
  default     = "s3-website-proxy"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
  default     = "ami-ff0fea8310f3" # LocalStack default Ubuntu AMI
}

variable "proxy_port" {
  description = "Port for the S3 website proxy"
  type        = number
  default     = 8888
}

variable "s3_bucket_name" {
  description = "S3 bucket name to proxy (for single-bucket mode, optional)"
  type        = string
  default     = ""
}
