output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.this.id
}

output "website_endpoint" {
  description = "Static website endpoint"
  value       = aws_s3_bucket_website_configuration.this.website_endpoint
}
