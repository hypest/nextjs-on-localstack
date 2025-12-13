#!/bin/bash
set -euo pipefail

# Build CI Node.js image for GitLab CI
# This script is called from .gitlab-ci.yml

echo "🔨 Building CI Node.js image..."

# Login to registry
docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" "http://host.docker.internal:5001"

# Build and push the image
IMAGE_TAG="host.docker.internal:5001/root/nextjs-on-localstack/ci-node:$CI_COMMIT_REF_SLUG"
docker build -f Dockerfile.ci-node -t "$IMAGE_TAG" .
docker push "$IMAGE_TAG"

echo "✅ CI Node.js image built and pushed: $IMAGE_TAG"