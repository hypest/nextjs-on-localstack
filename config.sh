#!/bin/bash
# Configuration file for the project
# Sourced by devcontainer and scripts

# Determine project root from this script's location
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INFRA_NAME="devcontainer-localstack"
APP_NAME="hello-nextjs"
APP_SRC_DIR="$PROJECT_ROOT/hello-nextjs"

export PROJECT_ROOT
export INFRA_NAME
export APP_NAME
export APP_SRC_DIR
export TF_VAR_infra_name="$INFRA_NAME"
export TF_VAR_bucket_base_name="$APP_NAME"