#!/bin/bash
set -euo pipefail

# Start GitLab containers.
# This script is idempotent - safe to run multiple times.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🐳 Starting GitLab containers..."

# docker-compose up -d is idempotent (won't restart if already running)
docker-compose -f $PROJECT_ROOT/docker-compose.gitlab.yml up -d

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