#!/usr/bin/env bash
set -euo pipefail

echo "Starting runtime services for development (supporting services + LocalStack)"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# script now lives in .devcontainer/scripts, repo root is two levels up
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Start supporting services (reuse existing script if present)
if [ -f "$WORKSPACE_ROOT/scripts/start-supporting-services.sh" ]; then
  echo "Using existing start-supporting-services.sh"
  bash "$WORKSPACE_ROOT/scripts/start-supporting-services.sh"
else
  echo "No start-supporting-services.sh found; skipping supporting services"
fi

# Start LocalStack (use improved helper if present)
if [ -f "$WORKSPACE_ROOT/scripts/start-localstack.sh" ]; then
  echo "Starting LocalStack via start-localstack.sh"
  bash "$WORKSPACE_ROOT/scripts/start-localstack.sh" || echo "start-localstack.sh failed"
else
  echo "No start-localstack.sh found; skipping LocalStack"
fi

# Start GitLab (use existing script if present)
if [ -f "$WORKSPACE_ROOT/scripts/start-gitlab.sh" ]; then
  echo "Starting GitLab via start-gitlab.sh"
  bash "$WORKSPACE_ROOT/scripts/start-gitlab.sh" || echo "start-gitlab.sh failed"
else
  echo "No start-gitlab.sh found; skipping GitLab"
fi

# Setup the GitLab project (use existing script if present)
if [ -f "$WORKSPACE_ROOT/scripts/setup-gitlab.sh" ]; then
  echo "Setting up the GitLab project via setup-gitlab.sh"
  bash "$WORKSPACE_ROOT/scripts/setup-gitlab.sh" || echo "setup-gitlab.sh failed"
else
  echo "No setup-gitlab.sh found; skipping setting up project in GitLab"
fi

echo "All requested services started"
