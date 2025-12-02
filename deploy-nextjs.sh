#!/bin/bash
set -euo pipefail

# Deploy Next.js static app to LocalStack S3
# Run from workspace root: ./deploy-nextjs.sh

cd /workspaces/localstack-terraform-dind-test

VENV=venv-deploy
SCRIPT=deploy-nextjs.py

# Create venv if missing
if [ ! -d "$VENV" ]; then
  echo "Creating venv..."
  python3 -m venv $VENV
fi

# Activate venv and install deps
source $VENV/bin/activate
pip install --upgrade pip
pip install boto3 botocore

# Deploy
echo "Deploying Next.js out/ to S3..."
python3 $SCRIPT

echo "✅ Deploy complete!"
echo "View app: http://hello-nextjs-dev-devcontainer-localstack.s3-website.us-east-1.localhost.localstack.cloud:4566/"
echo "Files count: aws --endpoint-url=http://localhost:4566 s3 ls s3://hello-nextjs-dev-devcontainer-localstack/ --recursive | wc -l"
