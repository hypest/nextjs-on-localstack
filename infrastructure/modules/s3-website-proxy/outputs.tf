output "container_name" {
  description = "Docker container name for S3 website proxy"
  value       = "s3-website-proxy-${var.environment}"
}

output "proxy_endpoint" {
  description = "S3 website proxy endpoint"
  value       = "http://localhost:${var.proxy_port}"
}

output "proxy_port" {
  description = "Port the proxy is listening on"
  value       = var.proxy_port
}

output "image_name" {
  description = "Docker image name for the proxy"
  value       = "localhost:5001/s3-website-proxy:latest"
}
