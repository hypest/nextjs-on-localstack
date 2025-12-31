output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.api_server.id
}

output "instance_public_ip" {
  description = "EC2 instance public IP"
  value       = aws_instance.api_server.public_ip
}

output "instance_private_ip" {
  description = "EC2 instance private IP"
  value       = aws_instance.api_server.private_ip
}

output "api_endpoint" {
  description = "API endpoint URL"
  value       = "http://${aws_instance.api_server.public_ip}:${var.api_port}/api/status"
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.api_sg.id
}
