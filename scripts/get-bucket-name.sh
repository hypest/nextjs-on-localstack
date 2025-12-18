#!/bin/bash
set -euo pipefail

# Get S3 bucket name from Terraform outputs for a given environment
# Usage: ./scripts/get-bucket-name.sh <environment>

ENVIRONMENT="${1:?Error: Provide environment argument (e.g., prod, staging, feature/mybranch)}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
INFRA_DIR="$PROJECT_ROOT/infrastructure"

# Sanitize environment to workspace name
WORKSPACE=$(echo "$ENVIRONMENT" | tr '/' '-' | tr ' ' '_')

# Switch to infrastructure directory and get bucket name
cd "$INFRA_DIR"
terraform workspace select "$WORKSPACE"
terraform output -raw s3_bucket_name