#!/bin/bash
set -euo pipefail

# Get Terraform environment name from current git branch
# Outputs the environment name to stdout

branch=$(git branch --show-current)

if [ "$branch" = "production" ]; then
  environment="prod"
elif [ "$branch" = "develop" ]; then
  environment="staging"
else
  # Sanitize branch name: replace / and spaces with -
  sanitized_branch=$(echo "$branch" | sed 's|[ /]|-|g')
  environment="$sanitized_branch"
fi

echo "$environment"