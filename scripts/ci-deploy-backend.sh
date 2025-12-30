#!/bin/bash
set -euo pipefail

# Deploy backend container to devcontainer-network
# This runs on the deploy runner with host Docker socket access

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Get environment and image tag
export DEPLOY_ENV="${DEPLOY_ENV:-$(./scripts/get-environment-from-branch.sh)}"
IMAGE_TAG="${CI_COMMIT_SHORT_SHA:-latest}"
REGISTRY_ENDPOINT="localhost:5001"  # Deploy runner uses host socket

echo "🚀 Deploying backend for environment: $DEPLOY_ENV"
echo "🏷️  Image tag: $IMAGE_TAG"

# Pull the image from registry
echo "⬇️  Pulling image from registry..."
docker pull ${REGISTRY_ENDPOINT}/backend-api:${IMAGE_TAG}

# Calculate port for this environment
export API_PORT=$(./scripts/calculate-port.sh "$DEPLOY_ENV")
echo "🔌 Using port: $API_PORT"

# Get instance ID from Terraform
cd "$PROJECT_ROOT/infrastructure"
"$PROJECT_ROOT/scripts/terraform-init" -reconfigure >/dev/null

WORKSPACE=$(echo "$DEPLOY_ENV" | tr '/' '-' | tr ' ' '_')
terraform workspace select "$WORKSPACE" 2>/dev/null || terraform workspace new "$WORKSPACE"

INSTANCE_ID=$(terraform output -raw ec2_instance_id 2>/dev/null || echo "ci-backend-${CI_COMMIT_SHORT_SHA:-local}")

# Stop existing container
CONTAINER_NAME="backend-api-${WORKSPACE}"
echo "🛑 Stopping existing container (if any)..."
docker stop "$CONTAINER_NAME" 2>/dev/null || true
docker rm "$CONTAINER_NAME" 2>/dev/null || true

# Run new container on devcontainer-network
echo "🐳 Starting new container..."
docker run -d \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  --network devcontainer-network \
  -p "${API_PORT}:3001" \
  -e NODE_ENV=production \
  -e EC2_INSTANCE_ID="$INSTANCE_ID" \
  -e ENVIRONMENT="$DEPLOY_ENV" \
  ${REGISTRY_ENDPOINT}/backend-api:${IMAGE_TAG}

# Wait for health check
echo "🏥 Waiting for backend to be healthy..."
for i in {1..30}; do
  if curl -sf http://${CONTAINER_NAME}:3001/health >/dev/null 2>&1; then
    echo "✅ Backend is healthy!"
    curl -s http://${CONTAINER_NAME}:3001/api/status | head -5
    break
  fi
  if [ $i -eq 30 ]; then
    echo "⚠️  Backend did not respond to health check"
  fi
  sleep 2
done

echo ""
echo "✅ Backend deployed successfully!"
echo "🌐 Container URL: http://${CONTAINER_NAME}:3001 (on devcontainer-network)"
echo "🌐 Host URL: http://localhost:${API_PORT}"
echo "🐳 Container: $CONTAINER_NAME"
echo "🏥 Health: http://localhost:${API_PORT}/health"
echo "📊 Status: http://localhost:${API_PORT}/api/status"
