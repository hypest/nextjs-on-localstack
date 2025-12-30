#!/bin/bash
set -euo pipefail

# DEPRECATED: S3 website proxy is now deployed via Terraform as EC2 infrastructure
# Use ./scripts/destroy-infra.sh instead to tear down all infrastructure

echo "⚠️  This script is deprecated."
echo ""
echo "The S3 website proxy is now deployed as infrastructure (EC2) via Terraform."
echo "To destroy it along with other infrastructure, run:"
echo ""
echo "  ./scripts/destroy-infra.sh <environment>"
echo ""
exit 1
