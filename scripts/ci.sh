#!/bin/bash
set -euo pipefail

REPO_ROOT="${PROJECT_ROOT:-$(git rev-parse --show-toplevel)}"
echo "🔍 Running CI checks from $REPO_ROOT"

# Lint and build Next.js
echo "   → Linting and building Next.js..."
cd "$APP_SRC_DIR"
npm ci
npm run lint
npm run build
cd "$REPO_ROOT"

# Validate Terraform
echo "   → Validating Terraform..."
cd "$REPO_ROOT/infrastructure"
terraform init
terraform validate
cd "$REPO_ROOT"

echo "✅ CI checks passed!"