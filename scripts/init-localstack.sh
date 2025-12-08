#!/bin/bash
set -euo pipefail

# Initialize LocalStack with required infrastructure
echo "Initializing LocalStack infrastructure..."

# Create Terraform state bucket
echo "Creating Terraform state bucket..."
awslocal s3 mb s3://terraform-state-devcontainer-localstack

echo "LocalStack infrastructure initialized successfully!"