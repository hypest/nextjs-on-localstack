#!/bin/bash

# Start supporting services for devcontainer (Docker Registry only)
echo "🚀 Starting supporting services..."

# Create network if it doesn't exist
docker network create devcontainer-network 2>/dev/null || echo "Network already exists"

start_or_reuse_container() {
    local name="$1" image="$2" extra_args="${3:-}"

    # If a running container exists, reuse it
    if docker ps --format "{{.Names}}" | grep -q "^${name}$"; then
        echo "✅ ${name} already running"
        return 0
    fi

    # If a stopped container exists, remove it (clean slate)
    if docker ps -a --format "{{.Names}}" | grep -q "^${name}$"; then
        echo "Found existing container named ${name} (stopped). Removing..."
        docker rm -f "${name}" >/dev/null 2>&1 || true
    fi

    echo "📦 Starting ${name}..."
    docker run -d --name "${name}" ${extra_args} "${image}" >/dev/null
}

## Start Docker Registry (for local ECR simulation)
# If registry-bridge.sh already started a registry named 'local_registry' (port 5001), reuse it.
if docker ps --format '{{.Names}}' | grep -q '^local_registry$'; then
    echo "✅ local_registry already running (reused)"
else
    # Ensure the volume exists
    docker volume inspect devcontainer_local_registry_data >/dev/null 2>&1 || \
        docker volume create devcontainer_local_registry_data >/dev/null

    start_or_reuse_container "local_registry" "registry:2" "--network devcontainer-network -p 5001:5000 -e REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/data -v devcontainer_local_registry_data:/data"
fi

# Connect registry to gitlab-network if it exists (for CI builds)
if docker network ls --format '{{.Name}}' | grep -q '^gitlab-network$'; then
    if ! docker inspect local_registry --format '{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}' | grep -q "$(docker network inspect gitlab-network --format '{{.Id}}' | cut -c1-12)"; then
        echo "🔗 Connecting registry to gitlab-network..."
        docker network connect gitlab-network local_registry
    fi
fi

echo "✅ Supporting services started!"
echo "   - Registry: localhost:5001 (host access)"
echo "   - Registry: local_registry:5000 (container access)"
