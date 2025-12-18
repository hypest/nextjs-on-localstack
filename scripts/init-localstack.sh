#!/bin/bash
set -euo pipefail

# Initialize LocalStack with required infrastructure
echo "Initializing LocalStack infrastructure..."

# Create Terraform state bucket
echo "Creating Terraform state bucket..."
awslocal s3 mb s3://terraform-state-${INFRA_NAME:?Error: INFRA_NAME not set. Source config.sh or set the environment variable.}

echo "LocalStack infrastructure initialized successfully!"