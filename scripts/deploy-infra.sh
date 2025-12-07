#!/bin/bash
set -euo pipefail

# Deploy Terraform infrastructure for a specific environment/workspace
# Usage: ./scripts/deploy-infra.sh <environment> [bucket_base_name=hello-nextjs]

ENVIRONMENT="${1:?Error: Provide environment (e.g., prod, staging, feature/mybranch)}"
BUCKET_BASE_NAME="${2:-hello-nextjs}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")/infrastructure"

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

echo "🚀 Deploying infrastructure for environment: $ENVIRONMENT"
echo "   Bucket base: $BUCKET_BASE_NAME"
echo "   Infra dir: $INFRA_DIR"

cd "$INFRA_DIR"

# Initialize Terraform to ensure modules and providers are up-to-date
echo "Initializing Terraform..."
terraform init

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

# Apply
echo "Applying Terraform..."
terraform apply -auto-approve \
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

# Conditionally deploy backend if EC2 module is present and backend-api exists
if terraform output ec2_instance_id >/dev/null 2>&1 && [[ -d "$PROJECT_ROOT/backend-api" ]]; then
    echo "🐳 Deploying backend API container..."
    "$SCRIPT_DIR/deploy-backend.sh" "$ENVIRONMENT"
else
    echo "ℹ️  Skipping backend deployment (EC2 not present or backend-api missing)"
fi
