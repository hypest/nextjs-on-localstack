variable "environment" {
  description = "Environment name (e.g., prod, staging, feature-branch)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "nextjs-backend"
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

variable "api_port" {
  description = "Port for the backend API"
  type        = number
  default     = 3001
}
