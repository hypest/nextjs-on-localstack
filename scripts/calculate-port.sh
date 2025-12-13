#!/bin/bash
set -euo pipefail

# Calculate unique port based on environment/branch name
# Usage: ./calculate-port.sh <environment>

ENVIRONMENT="${1:?Error: Provide environment (e.g., prod, staging, feature/mybranch)}"

# Special cases for known environments
if [[ "$ENVIRONMENT" == "prod" ]]; then
    echo "3001"
elif [[ "$ENVIRONMENT" == "staging" ]]; then
    echo "3002"
else
    # Feature branches: use hash of environment name for consistent port assignment
    ENV_HASH=$(echo -n "$ENVIRONMENT" | md5sum | cut -c1-4 | tr 'a-f' '0-9' | cut -c1-4)
    API_PORT=$((3003 + (16#${ENV_HASH:0:3} % 100)))
    echo "$API_PORT"
fi