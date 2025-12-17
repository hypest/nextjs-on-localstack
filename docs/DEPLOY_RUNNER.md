# GitLab CI/CD Deploy Runner Setup

## Overview

This project uses **two GitLab Runners** with different security profiles:

1. **Build Runner** (DinD) - For building images in isolation
2. **Deploy Runner** (Host Docker) - For deploying containers to devcontainer-network

## Architecture

```
┌──────────────────────────────────────────────────┐
│ GitLab CI/CD Pipeline                            │
├──────────────────────────────────────────────────┤
│                                                  │
│ Build Jobs (DinD Runner)                         │
│ ├─ build_ci_node_image   ┐                       │
│ ├─ build_ci_python_image │ Isolated              │
│ └─ build_backend         ┘ Secure                │
│                                                  │
│ Deploy Jobs (Deploy Runner w/ Host Docker)       │
│ ├─ deploy_app            ┐                       │
│ └─ deploy_backend        ┘ Access to             │
│                             devcontainer-network │
└──────────────────────────────────────────────────┘
```

## Setup

### Initial Setup

Run the complete GitLab setup which configures both runners:

```bash
./scripts/setup-gitlab.sh
```

This will:
1. Set up GitLab project
2. Register build runner with DinD
3. Register deploy runner with host Docker access

### Manual Deploy Runner Configuration

If you need to register the deploy runner separately:

```bash
# Get registration token from GitLab Admin Area
# http://localhost:8080/admin/runners

./scripts/configure-deploy-runner.sh <registration-token>
```

## Runner Configuration

### Build Runner (Default)
- **Executor**: Docker with DinD
- **Network**: gitlab-network
- **Security**: Isolated builds, no host access
- **Used by**: Build jobs (untagged or no specific tag)

### Deploy Runner
- **Executor**: Docker with host socket
- **Tag**: `deploy`
- **Network**: devcontainer-network
- **Docker Socket**: `/var/run/docker.sock` (host)
- **Security**: Can deploy to host Docker daemon
- **Used by**: Jobs tagged with `deploy`

## CI Job Configuration

### Using the Deploy Runner

Add the `deploy` tag to jobs that need host Docker access:

```yaml
my_deploy_job:
  stage: deploy
  tags:
    - deploy  # Uses deploy runner
  variables:
    DOCKER_HOST: "unix:///var/run/docker.sock"
    AWS_ENDPOINT_URL: "http://localstack-main:4566"  # Container name
  script:
    - docker ps  # Sees host containers
    - curl http://localstack-main:4566/_localstack/health
```

### Service Communication

Jobs on the deploy runner use Docker container names for service discovery:

- **LocalStack**: `localstack-main:4566`
- **Registry**: `localhost:5001` (via host socket)
- **Other containers**: Use container name on `devcontainer-network`

## Example Jobs

### Build Job (DinD)
```yaml
build_backend:
  stage: build
  image: docker:latest
  services:
    - name: docker:dind
      command: ["dockerd", "--host=tcp://0.0.0.0:2375", "--tls=false"]
  variables:
    DOCKER_HOST: tcp://docker:2375
    DOCKER_REGISTRY_ENDPOINT: "host.docker.internal:5001"
  script:
    - ./scripts/ci-build-backend.sh
```

### Deploy Job (Host Docker)
```yaml
deploy_backend:
  stage: deploy
  tags:
    - deploy
  variables:
    DOCKER_HOST: "unix:///var/run/docker.sock"
  script:
    - ./scripts/ci-deploy-backend.sh
```

## Security Considerations

### Deploy Runner Has Elevated Privileges

The deploy runner can:
- ✅ Deploy containers to host
- ✅ Access devcontainer-network
- ✅ Manage host Docker daemon
- ⚠️ Potentially interfere with host services

**Recommendation**: Only use for trusted deployment scripts, not for building untrusted code.

### Best Practices

1. **Build in DinD** - Keep builds isolated
2. **Deploy with host** - Only for final deployment step
3. **Use specific tags** - Don't run deploy jobs on build runner
4. **Review deployment scripts** - Ensure they're safe
5. **Limit deploy runner** - Set `run-untagged: false`

## Troubleshooting

### Deploy Runner Not Available

Check runner status:
```bash
docker exec gitlab-runner gitlab-runner verify
```

List registered runners:
```bash
docker exec gitlab-runner gitlab-runner list
```

### Job Stuck on "Pending"

1. Check if deploy runner is online in GitLab Admin
2. Verify job has correct tag: `deploy`
3. Check runner logs:
   ```bash
   docker logs gitlab-runner -f
   ```

### Container Can't Access LocalStack

Verify DNS resolution:
```bash
docker run --rm --network devcontainer-network alpine ping -c 1 localstack-main
```

Check LocalStack is on devcontainer-network:
```bash
docker inspect localstack-main | grep -A5 Networks
```

### Deploy Job Can't Access Host Docker

Verify socket is mounted:
```bash
docker exec gitlab-runner cat /etc/gitlab-runner/config.toml | grep volumes
```

Should show: `/var/run/docker.sock:/var/run/docker.sock`

## Maintenance

### Updating Runner Configuration

Edit configuration directly:
```bash
docker exec gitlab-runner vi /etc/gitlab-runner/config.toml
```

Or re-run configuration script:
```bash
./scripts/configure-deploy-runner.sh <token>
```

### Removing Runners

Unregister all runners:
```bash
docker exec gitlab-runner gitlab-runner unregister --all-runners
```

Unregister specific runner:
```bash
docker exec gitlab-runner gitlab-runner unregister --name "Deploy Runner (Host Docker Access)"
```

## References

- [GitLab Runner Docs](https://docs.gitlab.com/runner/)
- [Docker Executor](https://docs.gitlab.com/runner/executors/docker.html)
- [Security of Running Jobs](https://docs.gitlab.com/runner/security/)
