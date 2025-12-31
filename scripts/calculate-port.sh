#!/bin/bash
set -euo pipefail

# Calculate unique port based on environment and service type
# Usage: ./calculate-port.sh <environment> [service_type]
# service_type: "api" (default, 3000 range) or "proxy" (8000 range)

ENVIRONMENT="${1:?Error: Provide environment (e.g., prod, staging, feature/mybranch)}"
SERVICE_TYPE="${2:-api}"

# Define ranges based on service type
if [[ "$SERVICE_TYPE" == "proxy" ]]; then
    BASE_PORT=8890
    PROD_PORT=8888
    STAGING_PORT=8889
else
    BASE_PORT=3003
    PROD_PORT=3001
    STAGING_PORT=3002
fi

# Special cases for known environments
if [[ "$ENVIRONMENT" == "prod" ]]; then
    echo "$PROD_PORT"
elif [[ "$ENVIRONMENT" == "staging" ]]; then
    echo "$STAGING_PORT"
else
    # Feature branches: use hash of environment name for consistent port assignment
    # Use first 7 chars of md5 for a much larger space and lower collision probability
    ENV_HASH=$(echo -n "$ENVIRONMENT" | md5sum | cut -c1-7)
    # Convert hex to decimal and use modulo to fit in port range (100 ports)
    HASH_DEC=$((16#$ENV_HASH))
    PORT=$((BASE_PORT + (HASH_DEC % 100)))
    echo "$PORT"
fi