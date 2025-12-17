#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🛑 Stopping GitLab CI/CD environment..."

# Parse options
REMOVE_DATA=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --remove-data)
            REMOVE_DATA=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--remove-data]"
            echo "  --remove-data: Remove all GitLab data volumes (projects, configs, etc.)"
            exit 1
            ;;
    esac
done

# Unregister runners before stopping
echo "🏃 Unregistering GitLab runners..."
docker exec gitlab-runner gitlab-runner unregister --all-runners 2>/dev/null || echo "No runners to unregister or runner not responding"

# Clean up any leftover job containers
echo "🧹 Cleaning up runner job containers..."
docker ps -a --filter "name=runner-" --format "{{.Names}}" | while read container; do
    if [ ! -z "$container" ]; then
        docker rm -f "$container" 2>/dev/null || true
    fi
done

# Stop containers using docker-compose
echo "🐳 Stopping GitLab containers..."
docker-compose -f "$PROJECT_ROOT/docker-compose.gitlab.yml" down

# Remove runner config to ensure clean state on restart
echo "🧹 Cleaning runner configuration..."
docker volume rm gitlab_runner_config 2>/dev/null || echo "Runner config volume not found"

# Optionally remove data volumes
if [ "$REMOVE_DATA" = true ]; then
    echo "⚠️  Removing GitLab data volumes (projects, configs, logs)..."
    docker volume rm gitlab_config gitlab_data gitlab_logs 2>/dev/null || echo "Some volumes may not exist"
    echo "✅ All GitLab data removed"
else
    echo "💾 GitLab data volumes preserved (use --remove-data to remove)"
fi

# Remove SSH config entries
echo "🔧 Cleaning up SSH configuration..."
SSH_CONFIG="${HOME}/.ssh/config"
if [ -f "${SSH_CONFIG}" ]; then
    # Create a backup
    cp "${SSH_CONFIG}" "${SSH_CONFIG}.backup"
    # Remove GitLab localhost entry
    sed -i.tmp '/^Host localhost$/,/^$/d' "${SSH_CONFIG}" && rm "${SSH_CONFIG}.tmp" || true
    echo "SSH config cleaned (backup at ${SSH_CONFIG}.backup)"
fi

# Remove SSH known_hosts entries for localhost:2222
echo "🔧 Cleaning SSH known_hosts..."
if [ -f "${HOME}/.ssh/known_hosts" ]; then
    ssh-keygen -R "[localhost]:2222" 2>/dev/null || true
fi

echo ""
echo "✅ GitLab stopped successfully!"
echo ""
if [ "$REMOVE_DATA" = true ]; then
    echo "📋 All data removed. Next setup will create fresh GitLab instance."
else
    echo "📋 Data volumes preserved. Next setup will reuse existing projects."
    echo "   To start fresh, run: $0 --remove-data"
fi
echo ""
echo "🚀 To start GitLab again, run: ./scripts/start-gitlab.sh"
echo "🔧 To set up from scratch, run: ./scripts/setup-gitlab.sh"
