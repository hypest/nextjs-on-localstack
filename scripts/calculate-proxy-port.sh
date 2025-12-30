#!/bin/bash
set -euo pipefail

# Calculate unique proxy port based on environment/branch name
# Usage: ./calculate-proxy-port.sh <environment>

ENVIRONMENT="${1:?Error: Provide environment (e.g., prod, staging, feature/mybranch)}"

# Special cases for known environments
if [[ "$ENVIRONMENT" == "prod" ]]; then
    echo "8888"
elif [[ "$ENVIRONMENT" == "staging" ]]; then
    echo "8889"
else
    # Feature branches: use hash of environment name for consistent port assignment
    ENV_HASH=$(echo -n "$ENVIRONMENT" | md5sum | cut -c1-4 | tr 'a-f' '0-9' | cut -c1-4)
    PROXY_PORT=$((8890 + (16#${ENV_HASH:0:3} % 100)))
    echo "$PROXY_PORT"
fi
