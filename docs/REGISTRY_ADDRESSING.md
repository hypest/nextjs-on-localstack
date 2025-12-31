# Docker Registry Addressing Strategy

## Problem Statement

The local Docker registry needs to be accessed from different contexts with different addressing schemes:

1. **DinD (Docker-in-Docker) jobs** - Running inside `docker:dind` service containers
2. **Deploy runner jobs** - Using host Docker socket (`/var/run/docker.sock`)
3. **Host environment** - Direct access from devcontainer or Codespace

Additionally, the behavior differs between:

- **VS Code Devcontainers** - `host.docker.internal` works via `--add-host=host.docker.internal:host-gateway`
- **GitHub Codespaces** - `host.docker.internal` may not resolve correctly in DinD contexts

## Solution: Multi-Mode Addressing

### Registry Container Setup

The registry container (`local-registry`) is configured to:

- Run on **two networks**: `devcontainer-network` and `gitlab-network`
- Expose port mapping: `5001:5000` (host port 5001 → container port 5000)

```bash
docker run -d --name local-registry \
  --network devcontainer-network \
  -p 5001:5000 \
  registry:2

# Also connect to gitlab-network for CI jobs
docker network connect gitlab-network local-registry
```

### Addressing Modes

| Context                       | Address               | Reason                                        |
| ----------------------------- | --------------------- | --------------------------------------------- |
| **DinD jobs** (build)         | `local-registry:5000` | Container name resolution on `gitlab-network` |
| **Deploy jobs** (host socket) | `localhost:5001`      | Host port forwarding                          |
| **Image pulls**               | `localhost:5001`      | Runner uses host Docker daemon                |
| **Host CLI**                  | `localhost:5001`      | Direct port access                            |

### Implementation

#### 1. GitLab CI Configuration

**Build jobs (DinD):**

```yaml
build_ci_node_image:
  services:
    - name: docker:dind
      command:
        [
          "dockerd",
          "--host=tcp://0.0.0.0:2375",
          "--tls=false",
          "--insecure-registry=local-registry:5000",
        ]
  variables:
    DOCKER_REGISTRY_ENDPOINT: "local-registry:5000" # For push operations
  script:
    - ./scripts/build-ci-node-image.sh
```

**Image references (for pulling):**

```yaml
validate:
  image: localhost:5001/root/nextjs-on-localstack/ci-node:$CI_COMMIT_REF_SLUG
```

**Deploy jobs (host Docker):**

```yaml
deploy_backend:
  tags:
    - deploy
  variables:
    DOCKER_HOST: "unix:///var/run/docker.sock"
  script:
    - docker pull localhost:5001/backend-api:${CI_COMMIT_SHORT_SHA}
```

#### 2. Build Scripts

Scripts use `DOCKER_REGISTRY_ENDPOINT` with sensible defaults:

```bash
# scripts/build-ci-node-image.sh
REGISTRY_ENDPOINT="${DOCKER_REGISTRY_ENDPOINT:-local-registry:5000}"
IMAGE_TAG="$REGISTRY_ENDPOINT/root/nextjs-on-localstack/ci-node:$CI_COMMIT_REF_SLUG"
docker build -f Dockerfile.ci-node -t "$IMAGE_TAG" .
docker push "$IMAGE_TAG"
```

Default is `local-registry:5000` (works in CI), but can be overridden for local development.

#### 3. Network Connectivity

Auto-connect services to `gitlab-network` during startup:

```bash
# scripts/start-gitlab.sh
if docker ps --format '{{.Names}}' | grep -q '^local-registry$'; then
    docker network connect gitlab-network local-registry 2>/dev/null || true
fi

if docker ps --format '{{.Names}}' | grep -q '^localstack-main$'; then
    docker network connect gitlab-network localstack-main 2>/dev/null || true
fi
```

## Why This Works for Both Environments

### VS Code Devcontainers

- `host.docker.internal` works via devcontainer runArgs
- But we **don't rely on it** in CI jobs
- CI jobs use container names (`local-registry`, `localstack-main`)
- Host-based scripts use `localhost:PORT`

### GitHub Codespaces

- `host.docker.internal` may not work in DinD
- CI jobs use container names (works identically)
- Port forwarding to `localhost` works via Codespaces infrastructure
- No dependency on `host.docker.internal` for CI

## Insecure Registry Configuration

Both addressing modes must be configured as insecure registries:

```json
{
  "insecure-registries": ["localhost:5001", "local-registry:5000"]
}
```

Applied to:

1. Devcontainer's Docker daemon (`/etc/docker/daemon.json`)
2. DinD daemon via `--insecure-registry` flag
3. GitLab runner configuration

## Testing

### Test DinD Access

```bash
docker run --rm --network gitlab-network alpine:latest \
  wget -qO- http://local-registry:5000/v2/_catalog
```

### Test Host Access

```bash
curl http://localhost:5001/v2/_catalog
```

### Test Image Push (DinD)

```bash
docker run --rm --network gitlab-network \
  -v /var/run/docker.sock:/var/run/docker.sock \
  docker:latest sh -c '
    echo "FROM alpine:latest" | docker build -t local-registry:5000/test:latest -
    docker push local-registry:5000/test:latest
  '
```

### Test Image Pull (Host)

```bash
docker pull localhost:5001/test:latest
```

## Migration Notes

### Previous Approach (Broken in Codespaces)

- Used `host.docker.internal:5001` for all contexts
- Required `--add-host=host.docker.internal:host-gateway`
- Failed in Codespaces DinD jobs

### Current Approach (Works Everywhere)

- DinD jobs: `local-registry:5000` (shared network)
- Host jobs: `localhost:5001` (port forwarding)
- Image pulls: `localhost:5001` (runner uses host daemon)
- No dependency on `host.docker.internal`

## Related Files

- [`.gitlab-ci.yml`](/.gitlab-ci.yml) - CI job definitions
- [`scripts/build-ci-node-image.sh`](/scripts/build-ci-node-image.sh) - Build script
- [`scripts/start-supporting-services.sh`](/scripts/start-supporting-services.sh) - Registry setup
- [`scripts/start-gitlab.sh`](/scripts/start-gitlab.sh) - Network connectivity
- [`.devcontainer/devcontainer.json`](/.devcontainer/devcontainer.json) - Devcontainer config
