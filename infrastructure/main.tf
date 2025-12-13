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
    sqs        = var.localstack_endpoint
    s3         = var.localstack_endpoint
    dynamodb   = var.localstack_endpoint
    ec2        = var.localstack_endpoint
    apigateway = var.localstack_endpoint
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

# API Gateway for backend API routing
resource "aws_api_gateway_rest_api" "backend_api" {
  name        = "backend-api-${var.environment}"
  description = "Backend API for ${var.environment} environment"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "status" {
  rest_api_id = aws_api_gateway_rest_api.backend_api.id
  parent_id   = aws_api_gateway_rest_api.backend_api.root_resource_id
  path_part   = "status"
}

resource "aws_api_gateway_method" "status_get" {
  rest_api_id   = aws_api_gateway_rest_api.backend_api.id
  resource_id   = aws_api_gateway_resource.status.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "status_options" {
  rest_api_id   = aws_api_gateway_rest_api.backend_api.id
  resource_id   = aws_api_gateway_resource.status.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "status_integration" {
  rest_api_id = aws_api_gateway_rest_api.backend_api.id
  resource_id = aws_api_gateway_resource.status.id
  http_method = aws_api_gateway_method.status_get.http_method

  type                    = "HTTP"
  integration_http_method = "GET"
  uri                     = "http://backend-api-${var.environment}:${var.api_port}/api/status"

  # Enable CORS
  request_parameters = {
    "integration.request.header.Access-Control-Allow-Origin" = "'*'"
  }
}

resource "aws_api_gateway_integration" "status_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.backend_api.id
  resource_id = aws_api_gateway_resource.status.id
  http_method = aws_api_gateway_method.status_options.http_method

  type = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "status_200" {
  rest_api_id = aws_api_gateway_rest_api.backend_api.id
  resource_id = aws_api_gateway_resource.status.id
  http_method = aws_api_gateway_method.status_get.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_method_response" "status_options_200" {
  rest_api_id = aws_api_gateway_rest_api.backend_api.id
  resource_id = aws_api_gateway_resource.status.id
  http_method = aws_api_gateway_method.status_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
  }
}

resource "aws_api_gateway_integration_response" "status_integration_response" {
  depends_on = [aws_api_gateway_integration.status_integration]

  rest_api_id = aws_api_gateway_rest_api.backend_api.id
  resource_id = aws_api_gateway_resource.status.id
  http_method = aws_api_gateway_method.status_get.http_method
  status_code = aws_api_gateway_method_response.status_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

resource "aws_api_gateway_integration_response" "status_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.backend_api.id
  resource_id = aws_api_gateway_resource.status.id
  http_method = aws_api_gateway_method.status_options.http_method
  status_code = aws_api_gateway_method_response.status_options_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
  }
}

resource "aws_api_gateway_deployment" "backend_api_deployment" {
  depends_on = [aws_api_gateway_integration.status_integration, aws_api_gateway_integration.status_options_integration]

  rest_api_id = aws_api_gateway_rest_api.backend_api.id
}

resource "aws_api_gateway_stage" "backend_api_stage" {
  deployment_id = aws_api_gateway_deployment.backend_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.backend_api.id
  stage_name    = "prod"
}
