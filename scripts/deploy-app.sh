#!/bin/bash
set -euo pipefail

# Deploy Next.js static app to S3 for specific env/workspace
# Usage: ./scripts/deploy-app.sh <environment>
# Environment variable: DEPLOY_ENV (used if no argument provided)

ENVIRONMENT="${1:-${DEPLOY_ENV:?Error: Provide environment via argument or DEPLOY_ENV variable (e.g., prod, staging, feature/mybranch)}}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(dirname "$SCRIPT_DIR")}"
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

# Get bucket name from Terraform
BUCKET_NAME=$(./scripts/get-bucket-name.sh "$ENVIRONMENT")
echo "   Target bucket: $BUCKET_NAME"

# Determine API endpoint for this environment
cd "$INFRA_DIR"
API_GATEWAY_URL=$(terraform output -raw api_gateway_url | sed 's/amazonaws\.com/localhost.localstack.cloud:4566/')
API_ENDPOINT="${API_GATEWAY_URL}/status"
echo "   API endpoint: $API_ENDPOINT"

# Build Next.js static export
echo "📦 Building Next.js..."
cd "$APP_SRC_DIR"
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
