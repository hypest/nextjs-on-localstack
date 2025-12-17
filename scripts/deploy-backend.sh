#!/bin/bash
set -euo pipefail

# Build and deploy backend API as Lambda function
# This works with DinD in CI or locally

ENVIRONMENT="${1:-${DEPLOY_ENV:?Error: Provide environment via argument or DEPLOY_ENV variable (e.g., prod, staging, feature/mybranch)}}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKEND_DIR="$PROJECT_ROOT/backend-api"

echo "🚀 Building and deploying backend API as Lambda function for environment: $ENVIRONMENT"

# Determine registry endpoint (use environment variable or default to localhost)
REGISTRY_ENDPOINT="${DOCKER_REGISTRY_ENDPOINT:-localhost:5001}"

# Determine image tag (use git commit SHA in CI, or 'latest' locally)
IMAGE_TAG="${CI_COMMIT_SHORT_SHA:-latest}"

echo "📦 Building Docker image with tag: $IMAGE_TAG"

# Build the Docker image (Lambda-compatible)
cd "$BACKEND_DIR"
docker build -t backend-api:$IMAGE_TAG .

# Tag for registry
echo "🏷️  Tagging for registry: $REGISTRY_ENDPOINT"
docker tag backend-api:$IMAGE_TAG "$REGISTRY_ENDPOINT/backend-api:$IMAGE_TAG"

# Push to local registry (simulates ECR push)
echo "⬆️  Pushing to registry..."
docker push "$REGISTRY_ENDPOINT/backend-api:$IMAGE_TAG"

# Deploy Lambda function with Terraform
echo "☁️  Deploying Lambda function via Terraform..."
cd "$PROJECT_ROOT/infrastructure"

WORKSPACE=$(echo "$ENVIRONMENT" | tr '/' '-' | tr ' ' '_')
terraform workspace select "$WORKSPACE" 2>/dev/null || terraform workspace new "$WORKSPACE"

# Apply Terraform with image tag variable
terraform apply -auto-approve \
  -var="registry_endpoint=$REGISTRY_ENDPOINT" \
  -var="image_tag=$IMAGE_TAG" \
  -var="environment=$ENVIRONMENT"

# Get Lambda Function URL
FUNCTION_URL=$(terraform output -raw backend_lambda_url 2>/dev/null || echo "")

if [ -n "$FUNCTION_URL" ]; then
  echo ""
  echo "✅ Backend API Lambda function deployed!"
  echo "🌐 Lambda URL: $FUNCTION_URL"
  echo "📝 Function: backend-api-$WORKSPACE"
  echo ""
  echo "Test the API:"
  echo "  curl $FUNCTION_URL/health"
  echo "  curl $FUNCTION_URL/api/status"
else
  echo "⚠️  Could not retrieve Lambda Function URL"
  terraform output
fi