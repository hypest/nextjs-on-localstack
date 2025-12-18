#!/bin/bash
set -euo pipefail

# Build CI Python image for GitLab CI
# This script is called from .gitlab-ci.yml

echo "🔨 Building CI Python image..."

# Build and push the image (no auth needed for local registry)
# Default to local-registry:5000 for CI DinD environment
# CI jobs pass DOCKER_REGISTRY_ENDPOINT from .gitlab-ci.yml
REGISTRY_ENDPOINT="${DOCKER_REGISTRY_ENDPOINT:-local-registry:5000}"
IMAGE_TAG="$REGISTRY_ENDPOINT/root/nextjs-on-localstack/ci-python:$CI_COMMIT_REF_SLUG"
echo "📮 Using registry: $REGISTRY_ENDPOINT"
docker build -f Dockerfile.ci-python -t "$IMAGE_TAG" .
docker push "$IMAGE_TAG"

echo "✅ CI Python image built and pushed: $IMAGE_TAG"