#!/bin/bash

# Setup script for generic LocalStack + AWS devcontainer environment

echo "🚀 Setting up LocalStack + AWS + Terraform development environment..."

# Get the script directory and workspace root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(dirname "$SCRIPT_DIR")"

echo "📁 Working in: $WORKSPACE_ROOT"

# Set up Terraform infrastructure (if infrastructure/ exists)
if [ -d "$WORKSPACE_ROOT/infrastructure" ]; then
    echo "🏗️ Setting up Terraform infrastructure..."
    
    # Determine environment based on current git branch
    environment=$("$SCRIPT_DIR/get-environment-from-branch.sh")
    echo "Detected environment: $environment"
    
    # Deploy infrastructure using the dedicated script
    bash "$SCRIPT_DIR/deploy-infra.sh" "$environment" || echo "Infrastructure deployment failed - check config"
else
    echo "⚠️  No infrastructure/ directory found, skipping Terraform setup"
fi

# Start supporting services (Docker Registry)
echo "🔧 Starting supporting services..."
bash "$WORKSPACE_ROOT/scripts/start-supporting-services.sh"

# Start LocalStack using Docker-in-Docker
echo "🐳 Starting LocalStack..."
if [ -f "$WORKSPACE_ROOT/scripts/start-localstack.sh" ]; then
    bash "$WORKSPACE_ROOT/scripts/start-localstack.sh"
else
    echo "⚠️  start-localstack.sh not found, start manually"
fi

# Start GitLab using Docker Compose
echo "🐳 Starting GitLab..."
if [ -f "$WORKSPACE_ROOT/scripts/start-gitlab.sh" ]; then
    bash "$WORKSPACE_ROOT/scripts/start-gitlab.sh"
else
    echo "⚠️  start-gitlab.sh not found, start manually"
fi

# Set up GitLab project and SSH keys
echo "🔧 Setting up GitLab CI/CD..."
if [ -f "$WORKSPACE_ROOT/scripts/setup-gitlab.sh" ]; then
    bash "$WORKSPACE_ROOT/scripts/setup-gitlab.sh"
else
    echo "⚠️  setup-gitlab.sh not found, run manually"
fi

echo "✅ Setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Bootstrap your app (e.g., npx create-next-app@latest my-app)"
echo "2. Run your app dev server (e.g., npm run dev)"
echo "3. Access app at http://localhost:3000"
echo "4. LocalStack at http://localhost:4566"
echo "5. GitLab at http://localhost:8080"
echo ""
echo "🔍 Useful commands:"
echo "- awslocal sqs list-queues  # List queues (awslocal from awscli-local)"
echo "- aws --endpoint-url=http://localhost:4566 s3 ls  # AWS CLI"
echo "- terraform -chdir=infrastructure plan  # Preview infra"
echo "- terraform -chdir=infrastructure apply  # Apply infra"
echo "- scripts/start-localstack.sh  # Restart LocalStack"
echo "- scripts/stop-localstack.sh   # Stop LocalStack"
echo "- git push gitlab <branch>     # Push to GitLab CI/CD"
