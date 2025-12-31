#!/bin/bash
set -euo pipefail

# CI validation script for Next.js and Terraform
# This script is called from .gitlab-ci.yml

echo "🔍 Validating Next.js application..."
cd "$APP_SRC_DIR"
npm ci
npm run lint
npm run build

echo "🔍 Validating Terraform infrastructure..."
cd "$PROJECT_ROOT/infrastructure"
"$PROJECT_ROOT/scripts/terraform-init" -reconfigure
terraform validate

echo "✅ Validation successful!"
