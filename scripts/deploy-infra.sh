#!/bin/bash
set -euo pipefail

# Deploy Terraform infrastructure for a specific environment/workspace
# Usage: ./scripts/deploy-infra.sh <environment> [bucket_base_name=hello-nextjs]
# Environment variable: DEPLOY_ENV (used if no argument provided)

if [ -z "${1:-}" ] && [ -z "${DEPLOY_ENV:-}" ]; then
    export DEPLOY_ENV="$PROJECT_ROOT/scripts/get-environment-from-branch.sh"
    export DEPLOY_ENV=$("$DEPLOY_ENV")
fi

ENVIRONMENT="${1:-${DEPLOY_ENV:?Error: Provide environment via argument or DEPLOY_ENV variable (e.g., prod, staging, feature/mybranch)}}"
BUCKET_BASE_NAME="${2:-${APP_NAME:-hello-nextjs}}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(dirname "$SCRIPT_DIR")}"
INFRA_DIR="$PROJECT_ROOT/infrastructure"

# Protection: Confirm prod/staging deployments (skip in CI)
if [[ "$ENVIRONMENT" == "prod" || "$ENVIRONMENT" == "staging" ]]; then
    if [ -z "${GITLAB_CI:-}" ]; then
        echo "⚠️  WARNING: You are about to deploy to '$ENVIRONMENT' environment!"
        read -p "Are you sure you want to continue? (yes/no): " -r
        echo
        if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
            echo "❌ Deployment cancelled."
            exit 1
        fi
    else
        echo "ℹ️  CI environment detected - skipping confirmation for '$ENVIRONMENT'"
    fi
fi

echo "🚀 Deploying infrastructure for environment: $ENVIRONMENT"
echo "   Bucket base: $BUCKET_BASE_NAME"
echo "   Infra dir: $INFRA_DIR"

# CI-specific setup
if [ -n "${GITLAB_CI:-}" ]; then
    git config --global --add safe.directory /workspace
fi

# Calculate API port for this environment
API_PORT=$("$SCRIPT_DIR/calculate-port.sh" "$ENVIRONMENT")
echo "   API port: $API_PORT"

# Calculate proxy port for this environment
PROXY_PORT=$("$SCRIPT_DIR/calculate-proxy-port.sh" "$ENVIRONMENT")
echo "   Proxy port: $PROXY_PORT"

cd "$INFRA_DIR"

# Initialize Terraform to ensure modules and providers are up-to-date
echo "Initializing Terraform..."
$SCRIPT_DIR/terraform-init -reconfigure

# Select or create Terraform workspace matching environment
# Sanitize environment name for both workspace and bucket names
SANITIZED_ENV=$(echo "$ENVIRONMENT" | tr '/' '-' | tr ' ' '_')
WORKSPACE="$SANITIZED_ENV"
if ! terraform workspace select "$WORKSPACE" 2>/dev/null; then
    echo "Creating new Terraform workspace: $WORKSPACE (sanitized from $ENVIRONMENT)"
    terraform workspace new "$WORKSPACE"
else
    echo "Using existing workspace: $WORKSPACE (for $ENVIRONMENT)"
fi

# Plan (optional, comment out for auto-apply only)
# terraform plan -var="environment=$SANITIZED_ENV" -var="bucket_base_name=$BUCKET_BASE_NAME"

# Refresh state to sync with existing infrastructure
echo "Refreshing Terraform state..."
TF_VAR_api_port="$API_PORT" TF_VAR_proxy_port="$PROXY_PORT" terraform refresh \
    -var="environment=$SANITIZED_ENV" \
    -var="bucket_base_name=$BUCKET_BASE_NAME"

# Apply
echo "Applying Terraform..."
TF_VAR_api_port="$API_PORT" TF_VAR_proxy_port="$PROXY_PORT" terraform apply -auto-approve \
    -var="environment=$SANITIZED_ENV" \
    -var="bucket_base_name=$BUCKET_BASE_NAME"

# Output key values
echo ""
echo "✅ Infrastructure deployed!"
echo "S3 Bucket: $(terraform output -raw s3_bucket_name)"
echo "Website Endpoint: $(terraform output -raw s3_website_endpoint)"
echo "EC2 Instance: $(terraform output -raw ec2_instance_id)"
echo "API Endpoint: $(terraform output -raw api_endpoint)"
echo ""
