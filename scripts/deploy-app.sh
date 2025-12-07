#!/bin/bash
set -euo pipefail

# Deploy Next.js static app to S3 for specific env/workspace
# Usage: ./scripts/deploy-app.sh <environment>

ENVIRONMENT="${1:?Error: Provide environment (e.g., prod, staging, feature/mybranch)}"
BUCKET_BASE_NAME="hello-nextjs"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
INFRA_DIR="$PROJECT_ROOT/infrastructure"
APP_DIR="$PROJECT_ROOT/hello-nextjs"
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

# Switch to env workspace & get bucket
cd "$INFRA_DIR"
WORKSPACE=$(echo "$ENVIRONMENT" | tr '/' '-' | tr ' ' '_')
terraform workspace select "$WORKSPACE"
BUCKET_NAME=$(terraform output -raw s3_bucket_name)
echo "   Target bucket: $BUCKET_NAME"

# Determine API endpoint for this environment
if [[ "$ENVIRONMENT" == "prod" ]]; then
    API_PORT=3001
    API_SUBDOMAIN="api"
elif [[ "$ENVIRONMENT" == "staging" ]]; then
    API_PORT=3002
    API_SUBDOMAIN="api-staging"
else
    # Feature branches: use same port calculation as deploy-backend.sh
    ENV_HASH=$(echo "$ENVIRONMENT" | md5sum | cut -c1-4 | tr 'a-f' '0-9' | cut -c1-4)
    API_PORT=$((3003 + (16#${ENV_HASH:0:3} % 100)))
    # Sanitize environment name for subdomain
    SANITIZED_ENV=$(echo "$ENVIRONMENT" | tr '/' '-' | tr ' ' '_' | tr '[:upper:]' '[:lower:]')
    API_SUBDOMAIN="api-$SANITIZED_ENV"
fi
API_ENDPOINT="http://$API_SUBDOMAIN.localhost.localstack.cloud:$API_PORT/api/status"
echo "   API endpoint: $API_ENDPOINT"

# Build Next.js static export
echo "📦 Building Next.js..."
cd "$APP_DIR"
npm ci --only=production  # Fast install
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
echo "🌐 Website: http://${BUCKET_NAME}.s3-website.us-east-1.localhost.localstack.cloud:4566/"
