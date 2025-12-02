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

echo "🚀 Deploying app for environment: $ENVIRONMENT"

# Switch to env workspace & get bucket
cd "$INFRA_DIR"
WORKSPACE=$(echo "$ENVIRONMENT" | tr '/' '-' | tr ' ' '_')
terraform workspace select "$WORKSPACE"
BUCKET_NAME=$(terraform output -raw s3_bucket_name)
echo "   Target bucket: $BUCKET_NAME"

# Build Next.js static export
echo "📦 Building Next.js..."
cd "$APP_DIR"
npm ci --only=production  # Fast install
npm run build
npm run export
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
