#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🐳 Starting GitLab containers..."

docker-compose -f $PROJECT_ROOT/docker-compose.gitlab.yml up -d

echo "✅ GitLab containers started!"
echo ""
echo "⏳ GitLab is starting up (this may take a few minutes)..."
echo "   Access at: http://localhost:8080"
echo ""
echo "💡 Next steps:"
echo "   - If this is a fresh start, run: ./scripts/setup-gitlab.sh"
echo "   - If runners need reconfiguration, check: http://localhost:8080/admin/runners"
echo ""
echo "🔍 Check GitLab health: curl -s http://localhost:8080/-/health"