#!/bin/bash
set -euo pipefail

# Build and deploy backend API container for LocalStack EC2 simulation
# This simulates what would happen in real AWS with ECR + EC2 user-data

ENVIRONMENT="${1:?Error: Provide environment (e.g., prod, staging, feature/mybranch)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKEND_DIR="$PROJECT_ROOT/backend-api"

echo "🐳 Building backend API container for environment: $ENVIRONMENT"

# Build the Docker image
cd "$BACKEND_DIR"
echo "Building Docker image..."
docker build -t backend-api:latest .

# Tag for local registry
echo "Tagging for local registry..."
docker tag backend-api:latest localhost:5001/backend-api:latest

# Push to local registry (simulates ECR push)
echo "Pushing to local registry..."
docker push localhost:5001/backend-api:latest

# Assign port based on environment
if [[ "$ENVIRONMENT" == "prod" ]]; then
    API_PORT=3001
elif [[ "$ENVIRONMENT" == "staging" ]]; then
    API_PORT=3002
else
    # Feature branches: use hash of environment name for consistent port assignment
    ENV_HASH=$(echo "$ENVIRONMENT" | md5sum | cut -c1-4 | tr 'a-f' '0-9' | cut -c1-4)
    API_PORT=$((3003 + (16#${ENV_HASH:0:3} % 100)))
fi

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
docker run -d \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  -p "$API_PORT:3001" \
  -e NODE_ENV=production \
  -e EC2_INSTANCE_ID="$INSTANCE_ID" \
  -e ENVIRONMENT="$ENVIRONMENT" \
  localhost:5001/backend-api:latest

echo "✅ Backend API container deployed!"
echo "🌐 API available via API Gateway at: $(terraform output -raw api_gateway_url | sed 's/amazonaws\.com/localhost.localstack.cloud:4566/')/status"
echo "🐳 Container: $CONTAINER_NAME (port $API_PORT)"