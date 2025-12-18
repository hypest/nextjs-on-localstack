#!/bin/bash
# Configuration file for the project
# Sourced by devcontainer and scripts

PROJECT_NAME="devcontainer-localstack"
APP_NAME="hello-nextjs"

export PROJECT_NAME
export APP_NAME
export TF_VAR_project_name="$PROJECT_NAME"
export TF_VAR_bucket_base_name="$APP_NAME"