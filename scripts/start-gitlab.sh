#!/bin/bash
set -euo pipefail

# Start GitLab containers and register runners if needed.
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
        echo "   You may need to wait a bit more before registering runners"
    fi
    sleep 5
done

# Check if runners are already registered
RUNNER_COUNT=$(docker exec gitlab-runner gitlab-runner list 2>/dev/null | grep -c "Executor=docker" || true)
# Ensure RUNNER_COUNT is a valid integer
RUNNER_COUNT=${RUNNER_COUNT:-0}

if [ "$RUNNER_COUNT" -eq 0 ]; then
    echo ""
    echo "🏃 No runners found. Registering runners..."
    
    # Get registration token
    RUNNER_TOKEN=$(docker exec gitlab gitlab-rails runner "puts Gitlab::CurrentSettings.current_application_settings.runners_registration_token" 2>/dev/null | tail -1)
    
    if [ -z "$RUNNER_TOKEN" ]; then
        echo "❌ Could not get runner registration token"
        echo "   Run manually: ./scripts/setup-gitlab.sh"
        exit 1
    fi
    
    # Register build runner
    echo "📝 Registering build runner..."
    docker exec gitlab-runner gitlab-runner register \
      --non-interactive \
      --url "http://gitlab" \
      --registration-token "$RUNNER_TOKEN" \
      --executor "docker" \
      --docker-image "docker:latest" \
      --docker-privileged \
      --docker-volumes "/cache" \
      --docker-extra-hosts "host.docker.internal:host-gateway" \
      --docker-network-mode "gitlab-network" \
      --run-untagged="true" \
      --locked="false" \
      --access-level="not_protected" \
      --description "Build Runner (DinD)"
    
    # Register deploy runner
    echo "📝 Registering deploy runner..."
    docker exec gitlab-runner gitlab-runner register \
      --non-interactive \
      --url "http://gitlab" \
      --registration-token "$RUNNER_TOKEN" \
      --executor "docker" \
      --docker-image "docker:latest" \
      --docker-volumes "/var/run/docker.sock:/var/run/docker.sock" \
      --docker-volumes "/workspaces/nextjs-on-localstack:/workspaces/nextjs-on-localstack" \
      --docker-extra-hosts "host.docker.internal:host-gateway" \
      --docker-network-mode "devcontainer-network" \
      --tag-list "deploy,host-docker" \
      --run-untagged="false" \
      --locked="false" \
      --access-level="not_protected" \
      --description "Deploy Runner (Host Docker)"
    
    echo ""
    echo "✅ Runners registered successfully!"
    docker exec gitlab-runner gitlab-runner list
else
    echo ""
    echo "✅ Runners already registered ($RUNNER_COUNT found)"
    docker exec gitlab-runner gitlab-runner list
fi

echo ""
echo "🌐 GitLab is running at: http://localhost:8080"
echo "🏃 Runners: http://localhost:8080/admin/runners"