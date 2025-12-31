# Deploy S3 website proxy as Docker container (simulating EC2 deployment)
# This follows the same pattern as the backend API deployment

locals {
  container_name = "s3-website-proxy-${var.environment}"
  registry_endpoint = "localhost:5001"
  image_name = "${local.registry_endpoint}/s3-website-proxy:latest"
}

# Run the proxy container (image should be pre-built by CI)
resource "null_resource" "deploy_proxy_container" {
  triggers = {
    container_name         = local.container_name
    proxy_port             = var.proxy_port
    image_name             = local.image_name
    bucket_name            = var.bucket_name
    backend_container_name = var.backend_container_name
    api_gateway_url        = var.api_gateway_url
    api_gateway_hostname   = var.api_gateway_hostname
    api_gateway_stage      = var.api_gateway_stage
    # Force redeployment on every apply to ensure container is up-to-date
    timestamp              = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOF
      # Stop and remove existing container
      docker stop ${local.container_name} 2>/dev/null || true
      docker rm ${local.container_name} 2>/dev/null || true
      
      # Run the proxy container
      docker run -d \
        --name ${local.container_name} \
        --restart unless-stopped \
        --network devcontainer-network \
        -p ${var.proxy_port}:${var.proxy_port} \
        -e PROXY_PORT=${var.proxy_port} \
        -e BUCKET_NAME=${var.bucket_name} \
        -e BACKEND_CONTAINER_NAME=${var.backend_container_name} \
        -e API_GATEWAY_URL=${var.api_gateway_url} \
        -e API_GATEWAY_HOSTNAME=${var.api_gateway_hostname} \
        -e API_GATEWAY_STAGE=${var.api_gateway_stage} \
        ${local.image_name}
    EOF
  }
}
