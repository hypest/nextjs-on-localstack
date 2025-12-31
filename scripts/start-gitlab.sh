#!/bin/bash
set -euo pipefail

# Start GitLab containers.
# This script is idempotent - safe to run multiple times.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🐳 Starting GitLab containers..."

# docker-compose up -d is idempotent (won't restart if already running)
docker-compose -f $PROJECT_ROOT/docker-compose.gitlab.yml up -d

# Connect registry to gitlab-network if it exists (for CI builds)
if docker network ls --format '{{.Name}}' | grep -q '^gitlab-network$'; then
    if ! docker inspect local-registry --format '{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}' | grep -q "$(docker network inspect gitlab-network --format '{{.Id}}' | cut -c1-12)"; then
        echo "🔗 Connecting registry to gitlab-network..."
        docker network connect gitlab-network local-registry
    fi
fi

# Connect LocalStack to gitlab-network if it exists (for CI builds)
if docker ps --format '{{.Names}}' | grep -q '^localstack-main$'; then
    if ! docker inspect localstack-main --format '{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}' | grep -q "$(docker network inspect gitlab-network --format '{{.Id}}' | cut -c1-12)"; then
        echo "🔗 Connecting LocalStack to gitlab-network..."
        docker network connect gitlab-network localstack-main
    fi
fi

echo "✅ GitLab containers started!"
echo ""
echo "⏳ Waiting for GitLab to be ready..."

# Wait for GitLab to be accessible
for i in {1..60}; do
    if curl -s --max-time 2 "http://localhost:8080/-/health" > /dev/null 2>&1; then
        echo "✅ GitLab is ready!"
        break
    fi
    if [ $i -eq 60 ]; then
        echo "⚠️  GitLab is taking longer than expected to start"
    fi
    sleep 5
done

echo ""
echo "🌐 GitLab is running at: http://localhost:8080"
echo "🏃 Runners: http://localhost:8080/admin/runners"
echo "   (Note: Runners must have been previously registered via setup-gitlab.sh)"