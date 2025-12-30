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
    # Use first 7 chars of md5 for a much larger space and lower collision probability
    ENV_HASH=$(echo -n "$ENVIRONMENT" | md5sum | cut -c1-7)
    # Convert hex to decimal and use modulo to fit in port range (8890-8989)
    HASH_DEC=$((16#$ENV_HASH))
    PROXY_PORT=$((8890 + (HASH_DEC % 100)))
    echo "$PROXY_PORT"
fi
