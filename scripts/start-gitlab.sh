#!/bin/bash
set -euo pipefail

echo "🐳 Starting GitLab containers..."

docker-compose -f docker-compose.gitlab.yml up -d

echo "✅ GitLab started! Access at http://localhost:8080"