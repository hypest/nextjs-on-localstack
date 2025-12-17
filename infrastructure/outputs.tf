# Generic outputs - add your own module outputs here

output "local_registry_url" {
  description = "URL of the local Docker registry (for ECR simulation)"
  value       = "localhost:5001"
}

# Example module outputs (uncomment when using modules)
# output "example_sqs_queue_url" {
#   value = module.example_sqs.queue_url
# }
#
# output "example_s3_bucket_name" {
#   value = module.example_s3.bucket_name
# }
#
# output "example_dynamodb_table_name" {
#   value = module.example_dynamodb.table_name
# }
output "s3_website_endpoint" {
  description = "Website endpoint for the app on S3"
  value       = module.nextjs_s3.website_endpoint
}

output "s3_bucket_name" {
  description = "S3 bucket name for the app"
  value       = module.nextjs_s3.bucket_name
}

output "backend_lambda_url" {
  description = "Lambda Function URL for the backend API"
  value       = module.backend_lambda.function_url
}

output "backend_function_name" {
  description = "Lambda function name for the backend API"
  value       = module.backend_lambda.function_name
}

# Legacy EC2 outputs - commented out (replaced by Lambda)
# output "ec2_instance_id" {
#   description = "EC2 instance ID for backend API"
#   value       = module.backend_ec2.instance_id
# }
# 
# output "ec2_instance_public_ip" {
#   description = "EC2 instance public IP"
#   value       = module.backend_ec2.instance_public_ip
# }
# 
# output "api_endpoint" {
#   description = "Backend API endpoint URL"
#   value       = module.backend_ec2.api_endpoint
# }

output "api_gateway_url" {
  description = "API Gateway URL for the backend API (legacy - use Lambda URL instead)"
  value       = replace(replace(aws_api_gateway_stage.backend_api_stage.invoke_url, "https://", "http://"), "amazonaws.com", "localhost.localstack.cloud:4566")
}
