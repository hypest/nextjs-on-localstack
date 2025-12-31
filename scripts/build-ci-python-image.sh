#!/bin/bash
set -euo pipefail

# Build CI Python image for GitLab CI
# This script is called from .gitlab-ci.yml

# Wait for Docker daemon to be ready
echo "⏳ Waiting for Docker daemon..."
for i in $(seq 1 30); do
    if docker info >/dev/null 2>&1; then
        echo "✅ Docker daemon is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ Docker daemon not ready after 60s"
        exit 1
    fi
    echo "Waiting for Docker daemon... ($i/30)"
    sleep 2
done

echo "🔨 Building CI Python image..."

# Force rebuild if Dockerfile or build script changed
SHOULD_BUILD=false
if [ -z "${CI_COMMIT_BEFORE_SHA:-}" ] || [ -z "${CI_COMMIT_SHA:-}" ]; then
    SHOULD_BUILD=true
elif git diff --name-only "$CI_COMMIT_BEFORE_SHA" "$CI_COMMIT_SHA" 2>/dev/null | grep -E '(Dockerfile.ci-python|scripts/build-ci-python-image.sh)'; then
    echo "Dockerfile or build script changed, forcing rebuild"
    SHOULD_BUILD=true
elif ! curl -sf --max-time 5 "http://${DOCKER_REGISTRY_ENDPOINT:-local-registry:5000}/v2/root/nextjs-on-localstack/ci-python/tags/list" | jq -e ".tags[]? | select(. == \"$CI_COMMIT_REF_SLUG\")" > /dev/null 2>&1; then
    echo "Image not found in registry, building"
    SHOULD_BUILD=true
fi

if [ "$SHOULD_BUILD" = false ]; then
    echo "Image already exists, skipping build"
    exit 0
fi

# Build and push the image (no auth needed for local registry)
# Default to local-registry:5000 for CI DinD environment
# CI jobs pass DOCKER_REGISTRY_ENDPOINT from .gitlab-ci.yml
REGISTRY_ENDPOINT="${DOCKER_REGISTRY_ENDPOINT:-local-registry:5000}"
IMAGE_TAG="$REGISTRY_ENDPOINT/root/nextjs-on-localstack/ci-python:$CI_COMMIT_REF_SLUG"
echo "📮 Using registry: $REGISTRY_ENDPOINT"
docker build -f Dockerfile.ci-python -t "$IMAGE_TAG" .
docker push "$IMAGE_TAG"

echo "✅ CI Python image built and pushed: $IMAGE_TAG"