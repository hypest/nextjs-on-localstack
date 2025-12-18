#!/bin/bash
# Configuration file for the project
# Sourced by devcontainer and scripts

INFRA_NAME="devcontainer-localstack"
APP_NAME="hello-nextjs"

export INFRA_NAME
export APP_NAME
export TF_VAR_infra_name="$INFRA_NAME"
export TF_VAR_bucket_base_name="$APP_NAME"