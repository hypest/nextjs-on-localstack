#!/bin/bash
# Configuration file for the project
# Sourced by devcontainer and scripts

# Determine project root from this script's location
PROJECT_ROOT="$(pwd)"

INFRA_NAME="toyaws"
APP_NAME="helloapp"
APP_SRC_DIR="$PROJECT_ROOT/hello-nextjs"

export PROJECT_ROOT
export INFRA_NAME
export APP_NAME
export APP_SRC_DIR
export TF_VAR_infra_name="$INFRA_NAME"
export TF_VAR_bucket_base_name="$APP_NAME"

export TF_BACKEND_CONFIG="-backend-config=bucket=terraform-state-${INFRA_NAME}"