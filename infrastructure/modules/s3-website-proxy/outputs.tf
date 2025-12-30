output "instance_id" {
  description = "EC2 instance ID for S3 website proxy"
  value       = aws_instance.proxy_server.id
}

output "instance_public_ip" {
  description = "EC2 instance public IP"
  value       = aws_instance.proxy_server.public_ip
}

output "proxy_endpoint" {
  description = "S3 website proxy endpoint"
  value       = "http://${aws_instance.proxy_server.public_ip}:${var.proxy_port}"
}

output "proxy_port" {
  description = "Port the proxy is listening on"
  value       = var.proxy_port
}
