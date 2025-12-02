#!/bin/bash
set -euo pipefail

# Destroy Terraform infrastructure for a specific environment/workspace
# Usage: ./scripts/destroy-infra.sh <environment>

ENVIRONMENT="${1:?Error: Provide environment (e.g., prod, staging, feature/mybranch)}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")/infrastructure"

echo "🗑️  Destroying infrastructure for environment: $ENVIRONMENT"

cd "$INFRA_DIR"

WORKSPACE=$(echo "$ENVIRONMENT" | tr '/' '-' | tr ' ' '_')
if terraform workspace select "$WORKSPACE" 2>/dev/null; then
    echo "Using workspace: $WORKSPACE (for $ENVIRONMENT)"
else
    echo "No workspace $WORKSPACE found (tried sanitized: $WORKSPACE), skipping."
    exit 0
fi

terraform destroy -auto-approve -var="environment=$ENVIRONMENT"

echo "✅ Destruction complete for $ENVIRONMENT"
