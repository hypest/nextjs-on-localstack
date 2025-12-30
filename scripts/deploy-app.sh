#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Deploy Next.js static app to S3 for specific env/workspace
# Usage: ./scripts/deploy-app.sh <environment>
# Environment variable: DEPLOY_ENV (used if no argument provided)

if [ -z "${1:-}" ] && [ -z "${DEPLOY_ENV:-}" ]; then
    export DEPLOY_ENV=$("$PROJECT_ROOT/scripts/get-environment-from-branch.sh")
fi

ENVIRONMENT="${1:-${DEPLOY_ENV:?Error: Provide environment via argument or DEPLOY_ENV variable (e.g., prod, staging, feature/mybranch)}}"

INFRA_DIR="$PROJECT_ROOT/infrastructure"
DEPLOY_PY="$PROJECT_ROOT/deploy-nextjs.py"  # Updated to take bucket arg
VENV="$PROJECT_ROOT/venv-deploy"

# Protection: Confirm prod/staging deployments
if [[ "$ENVIRONMENT" == "prod" || "$ENVIRONMENT" == "staging" ]]; then
    echo "⚠️  WARNING: You are about to deploy to '$ENVIRONMENT' environment!"
    read -p "Are you sure you want to continue? (yes/no): " -r
    echo
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo "❌ Deployment cancelled."
        exit 1
    fi
fi

echo "🚀 Deploying app for environment: $ENVIRONMENT"

# CI-specific setup
if [ -n "${GITLAB_CI:-}" ]; then
    git config --global --add safe.directory /workspace
fi

# Initialize Terraform to ensure we can access outputs
echo "Initializing Terraform..."
cd "$INFRA_DIR"
"$PROJECT_ROOT/scripts/terraform-init" -reconfigure > /dev/null

# Get bucket name from Terraform
cd "$PROJECT_ROOT"
BUCKET_NAME=$(./scripts/get-bucket-name.sh "$ENVIRONMENT")
echo "   Target bucket: $BUCKET_NAME"

# Determine API endpoint for this environment
# With the unified proxy, the API is always at /api relative to the frontend
API_ENDPOINT="/api/status"
echo "   API endpoint: $API_ENDPOINT"

# Build Next.js static export
echo "📦 Building Next.js..."
cd "$APP_SRC_DIR"
npm ci --only=production  # Fast install

# Unified build: No basePath needed as the proxy handles bucket mapping
echo "   Building with unified proxy routing (API at $API_ENDPOINT)"
NEXT_PUBLIC_API_ENDPOINT="$API_ENDPOINT" npm run build
echo "   Build complete: out/ ready"

# Deploy via Python (boto3)
cd "$PROJECT_ROOT"
if [ ! -d "$VENV" ]; then
  echo "Creating venv..."
  python3 -m venv "$VENV"
fi
source "$VENV/bin/activate"
pip install --upgrade pip boto3 botocore
python3 "$DEPLOY_PY" "$BUCKET_NAME"

echo "✅ App deployed to $BUCKET_NAME"
if [ "${CODESPACES:-}" = "true" ] && [ -n "${CODESPACE_NAME:-}" ]; then
  # In Codespaces, use the S3 website proxy (deployed as Docker container)
  # The proxy translates path-style URLs to virtual-host URLs for LocalStack
  cd "$INFRA_DIR"
  PROXY_PORT=$(terraform output -raw s3_proxy_port)
  cd "$PROJECT_ROOT"
  
  WEBSITE_URL="https://${CODESPACE_NAME}-${PROXY_PORT}.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}/${BUCKET_NAME}/"
else
  WEBSITE_URL="http://${BUCKET_NAME}.s3-website.us-east-1.localhost.localstack.cloud:4566${BASE_PATH}/"
fi
echo "🌐 Website: $WEBSITE_URL"
