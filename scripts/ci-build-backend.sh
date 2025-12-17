#!/bin/bash
set -euo pipefail

# Build backend Docker image and push to registry
# This runs in DinD (Docker-in-Docker) environment

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Get environment and image tag
export DEPLOY_ENV="${DEPLOY_ENV:-$(./scripts/get-environment-from-branch.sh)}"
IMAGE_TAG="${CI_COMMIT_SHORT_SHA:-latest}"
REGISTRY_ENDPOINT="${DOCKER_REGISTRY_ENDPOINT:-localhost:5001}"

echo "🏗️  Building backend for environment: $DEPLOY_ENV"
echo "📦 Image tag: $IMAGE_TAG"
echo "📮 Registry: $REGISTRY_ENDPOINT"

# Build the image
cd "$PROJECT_ROOT/backend-api"
docker build -t backend-api:${IMAGE_TAG} .

# Tag for registry
docker tag backend-api:${IMAGE_TAG} ${REGISTRY_ENDPOINT}/backend-api:${IMAGE_TAG}

# Push to registry
echo "⬆️  Pushing to registry..."
docker push ${REGISTRY_ENDPOINT}/backend-api:${IMAGE_TAG}

echo "✅ Backend image built and pushed: ${REGISTRY_ENDPOINT}/backend-api:${IMAGE_TAG}"
