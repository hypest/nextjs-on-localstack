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
    container_name = local.container_name
    proxy_port     = var.proxy_port
    image_name     = local.image_name
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
        ${local.image_name}
    EOF
  }
}
