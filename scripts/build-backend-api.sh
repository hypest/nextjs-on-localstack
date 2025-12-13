#!/bin/bash
set -euo pipefail

# Build and push backend API image for GitLab CI
# This script is called from .gitlab-ci.yml

echo "🔨 Building backend API image..."

# Build the image
docker build -t backend-api:latest ./backend-api

# Tag and push to registry
docker tag backend-api:latest "$DOCKER_REGISTRY_ENDPOINT/backend-api:latest"
docker push "$DOCKER_REGISTRY_ENDPOINT/backend-api:latest"

echo "✅ Backend API image built and pushed: $DOCKER_REGISTRY_ENDPOINT/backend-api:latest"