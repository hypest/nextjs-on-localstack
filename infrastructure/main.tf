terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  skip_region_validation      = true
  s3_use_path_style           = true

  endpoints {
    sqs      = var.localstack_endpoint
    s3       = var.localstack_endpoint
    dynamodb = var.localstack_endpoint
    ec2      = var.localstack_endpoint
    # Add more services as needed, e.g.:
    # iam     = var.localstack_endpoint
  }
}

# Example modules - uncomment and customize for your app
# module "example_sqs" {
#   source = "./modules/sqs"
# 
#   queue_name   = "my-app-queue"
#   environment  = var.environment
#   project_name = var.project_name
# }
# 
# module "example_s3" {
#   source = "./modules/s3"
# 
#   bucket_name  = "my-app-bucket"
#   environment  = var.environment
#   project_name = var.project_name
# }
# 
# module "example_dynamodb" {
#   source = "./modules/dynamodb"
# 
#   table_name   = "my-app-table"
#   environment  = var.environment
#   project_name = var.project_name
# }

module "nextjs_s3" {
  source = "./modules/s3"

  bucket_name  = var.bucket_base_name
  environment  = var.environment
  project_name = var.project_name
}

module "backend_ec2" {
  source = "./modules/ec2"

  environment  = var.environment
  project_name = var.project_name
}
