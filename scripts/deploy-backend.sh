#!/bin/bash
set -euo pipefail

# Build and deploy backend API container for LocalStack EC2 simulation
# This simulates what would happen in real AWS with ECR + EC2 user-data

ENVIRONMENT="${1:-${DEPLOY_ENV:?Error: Provide environment via argument or DEPLOY_ENV variable (e.g., prod, staging, feature/mybranch)}}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKEND_DIR="$PROJECT_ROOT/backend-api"

echo "🐳 Building backend API container for environment: $ENVIRONMENT"

# Build the Docker image
cd "$BACKEND_DIR"
echo "Building Docker image..."
docker build -t backend-api:latest .

# Determine registry endpoint (use environment variable or default to localhost)
REGISTRY_ENDPOINT="${DOCKER_REGISTRY_ENDPOINT:-localhost:5001}"

# Tag for local registry
echo "Tagging for local registry..."
docker tag backend-api:latest "$REGISTRY_ENDPOINT/backend-api:latest"

# Push to local registry (simulates ECR push)
echo "Pushing to local registry..."
docker push "$REGISTRY_ENDPOINT/backend-api:latest"

# Assign port based on environment
API_PORT=$("$SCRIPT_DIR/calculate-port.sh" "$ENVIRONMENT")
echo "Using port $API_PORT for environment $ENVIRONMENT"

# Get EC2 instance ID from Terraform (simulating metadata service)
cd "$PROJECT_ROOT/infrastructure"
WORKSPACE=$(echo "$ENVIRONMENT" | tr '/' '-' | tr ' ' '_')
terraform workspace select "$WORKSPACE" 2>/dev/null || echo "Warning: Could not select workspace $WORKSPACE"
INSTANCE_ID=$(terraform output -raw ec2_instance_id 2>/dev/null || echo "local-instance-$ENVIRONMENT")

# Stop any existing container for this environment
CONTAINER_NAME="backend-api-$(echo "$ENVIRONMENT" | tr '/' '-' | tr ' ' '_')"
docker stop "$CONTAINER_NAME" 2>/dev/null || true
docker rm "$CONTAINER_NAME" 2>/dev/null || true

# Run the container
BRANCH_NAME="${CI_COMMIT_REF_NAME:-$(git branch --show-current)}"
docker run -d \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  --network devcontainer-network \
  -e BRANCH_NAME="$BRANCH_NAME" \
  -p "$API_PORT:3001" \
  -e NODE_ENV=production \
  -e EC2_INSTANCE_ID="$INSTANCE_ID" \
  -e ENVIRONMENT="$ENVIRONMENT" \
  "$REGISTRY_ENDPOINT/backend-api:latest"

echo "✅ Backend API container deployed!"
echo "🌐 API available via API Gateway at: $(terraform output -raw api_gateway_url | sed 's/amazonaws\.com/localhost.localstack.cloud:4566/')/status"
echo "🐳 Container: $CONTAINER_NAME (port $API_PORT)"