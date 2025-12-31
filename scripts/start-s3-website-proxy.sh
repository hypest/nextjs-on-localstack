#!/bin/bash
set -euo pipefail

# DEPRECATED: S3 website proxy is now deployed via Terraform as EC2 infrastructure
# Use ./scripts/deploy-infra.sh instead, which provisions the proxy automatically

echo "⚠️  This script is deprecated."
echo ""
echo "The S3 website proxy is now deployed as infrastructure (EC2) via Terraform."
echo "It gets provisioned automatically when you run:"
echo ""
echo "  ./scripts/deploy-infra.sh <environment>"
echo ""
echo "The proxy will be available at the port shown in Terraform outputs."
echo ""
exit 1
