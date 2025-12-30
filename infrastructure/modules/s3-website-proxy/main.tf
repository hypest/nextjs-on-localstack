# Deploy S3 website proxy as Docker container (simulating EC2 deployment)
# This follows the same pattern as the backend API deployment

locals {
  container_name = "s3-website-proxy-${var.environment}"
  registry_endpoint = "localhost:5001"
  image_name = "${local.registry_endpoint}/s3-website-proxy:latest"
}

# Build and push the nginx proxy image
resource "null_resource" "build_proxy_image" {
  triggers = {
    # Rebuild when nginx config changes
    nginx_config = filemd5("${path.module}/nginx.conf.template")
    dockerfile   = filemd5("${path.module}/Dockerfile")
  }

  provisioner "local-exec" {
    command = <<-EOF
      # Build the nginx proxy image
      docker build -t s3-website-proxy:latest ${path.module}
      
      # Tag for local registry
      docker tag s3-website-proxy:latest ${local.image_name}
      
      # Push to local registry
      docker push ${local.image_name}
    EOF
  }
}

# Run the proxy container
resource "null_resource" "deploy_proxy_container" {
  depends_on = [null_resource.build_proxy_image]

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

  provisioner "local-exec" {
    when    = destroy
    command = "docker stop ${local.container_name} 2>/dev/null || true && docker rm ${local.container_name} 2>/dev/null || true"
  }
}
