#!/bin/bash
set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
echo "🔍 Running CI checks from $REPO_ROOT"

# Lint and build Next.js
echo "   → Linting and building Next.js..."
cd "$REPO_ROOT/hello-nextjs"
npm ci
npm run lint
npm run build
cd "$REPO_ROOT"

# Validate Terraform
echo "   → Validating Terraform..."
cd "$REPO_ROOT/infrastructure"
AWS_ENDPOINT_URL=http://localhost:4566 terraform init
AWS_ENDPOINT_URL=http://localhost:4566 terraform validate
cd "$REPO_ROOT"

echo "✅ CI checks passed!"