#!/bin/bash
set -euo pipefail

# Configure GitLab runner for CI/CD with DinD support
# This script should be run after GitLab and runner are started

echo "🔧 Configuring GitLab runner..."

# Wait for runner container to be available
for i in {1..30}; do
    if docker ps --format '{{.Names}}' | grep -q '^gitlab-runner$'; then
        break
    fi
    echo "Waiting for gitlab-runner container... (${i}/30)"
    sleep 2
done

# Write runner configuration
docker exec gitlab-runner sh -c 'cat > /etc/gitlab-runner/config.toml << "EOF"
concurrent = 1
check_interval = 0
connection_max_age = "15m0s"
shutdown_timeout = 0

[session_server]
  session_timeout = 1800

[[runners]]
  name = "Local Docker Runner"
  url = "http://gitlab"
  id = 4
  token = "glrtr-xzCUk8piVZtJK51QJ8K4"
  token_obtained_at = 2025-12-14T23:57:32Z
  token_expires_at = 0001-01-01T00:00:00Z
  executor = "docker"
  [runners.cache]
    MaxUploadedArchiveSize = 0
    [runners.cache.s3]
    [runners.cache.gcs]
    [runners.cache.azure]
  [runners.docker]
    tls_verify = false
    image = "docker:latest"
    privileged = true
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    disable_cache = false
    volumes = ["/cache"]
    extra_hosts = ["host.docker.internal:host-gateway"]
    network_mode = "gitlab-network"
    shm_size = 0
    network_mtu = 0
EOF'

# Restart runner to apply config
docker restart gitlab-runner

echo "✅ GitLab runner configured successfully!"
