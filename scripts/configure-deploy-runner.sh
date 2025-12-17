#!/bin/bash
set -euo pipefail

# Configure a dedicated GitLab Runner for deployment jobs
# This runner has access to the host Docker socket, allowing it to:
# - Deploy containers to devcontainer-network
# - Access LocalStack and other host services
# - Manage docker-compose deployments

echo "🔧 Configuring GitLab deploy runner with host Docker access..."

# Get the registration token (must be set in environment or passed as argument)
REGISTRATION_TOKEN="${GITLAB_RUNNER_DEPLOY_TOKEN:-${1:-}}"

if [ -z "$REGISTRATION_TOKEN" ]; then
    echo "❌ Error: Registration token required"
    echo "Usage: $0 <registration-token>"
    echo "Or set GITLAB_RUNNER_DEPLOY_TOKEN environment variable"
    echo ""
    echo "Get token from: http://localhost:8080/admin/runners"
    exit 1
fi

# Wait for GitLab Runner to be ready
echo "⏳ Waiting for GitLab Runner to be ready..."
for i in {1..30}; do
    if docker exec gitlab-runner gitlab-runner verify 2>/dev/null | grep -q "is alive"; then
        echo "✅ Runner service is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ Timeout waiting for runner"
        exit 1
    fi
    sleep 2
done

# Register deploy runner with host Docker socket access
echo "📝 Registering deploy runner..."
docker exec gitlab-runner gitlab-runner register \
  --non-interactive \
  --url "http://gitlab" \
  --registration-token "$REGISTRATION_TOKEN" \
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
  --description "Deploy Runner (Host Docker Access)"

echo ""
echo "✅ Deploy runner configured successfully!"
echo ""
echo "📋 Runner details:"
echo "   - Tags: deploy, host-docker"
echo "   - Network: devcontainer-network"
echo "   - Docker socket: /var/run/docker.sock (host)"
echo "   - Workspace: /workspaces/nextjs-on-localstack (mounted)"
echo ""
echo "🎯 Jobs tagged with 'deploy' will:"
echo "   - Have direct access to host Docker daemon"
echo "   - Can deploy containers to devcontainer-network"
echo "   - Can access LocalStack at localhost:4566"
echo "   - Can access local registry at localhost:5001"
echo ""
echo "⚠️  Note: This runner is less isolated than DinD runners"
echo "   Use only for deployment jobs, not for building untrusted code"
