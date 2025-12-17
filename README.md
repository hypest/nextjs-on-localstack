# Generic LocalStack + AWS Devcontainer Template

A VS Code devcontainer template for local AWS development with **LocalStack**, **Terraform**, **Docker-in-Docker (dinD)**, and supporting tools. Perfect for bootstrapping any app (Next.js, Python, Go, etc.) that needs local AWS emulation – no Ruby/Rails assumptions.

## 🏗️ Features

- **LocalStack** (SQS, S3, DynamoDB, etc.) via Docker.
- **Terraform** with example modules (SQS/S3/DynamoDB).
- **dinD** for running AWS services + local Docker registry (ECR sim).
- **Tools**: AWS CLI, Terraform, awslocal (`awscli-local`), jq, httpie, Node 20.
- **VS Code**: AWS Toolkit, LocalStack Toolkit, Terraform, Prettier/ESLint/TS.
- **Scripts**: `setup.sh`, `start/stop-localstack.sh`, `start-supporting-services.sh` (registry).

## 🚀 Quick Start

### 1. Open in VS Code

- Clone/fork this repo.
- **Reopen in Container** (Dev Containers extension).

### 2. Setup Environment

```bash
./scripts/setup.sh
```

- Starts LocalStack (4566), Docker registry (5001).
- Runs `terraform init/apply` (empty by default; uncomment modules).

### 3. Bootstrap Your App (e.g., Next.js)

```bash
npx create-next-app@latest my-app --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"
cd my-app
npm run dev  # http://localhost:3000
```

### 4. Use LocalStack

```bash
# Health check
curl http://localhost:4566/health

# awslocal (pip-installed awscli-local)
awslocal sqs list-queues

# AWS CLI
aws --endpoint-url=http://localhost:4566 s3 ls
```

### 5. Terraform Infra

```bash
cd infrastructure
terraform init
terraform plan  # Empty/no-op by default
# Edit main.tf to uncomment modules, then apply
terraform apply
```

## 🏢 Architecture

```
.
├── .devcontainer/     # Dev env (Node/Terraform/AWS/LocalStack)
├── infrastructure/    # Terraform (provider + modules/sqs|s3|dynamodb)
├── scripts/           # Utils (setup, localstack, registry, CI/CD)
├── docs/              # Documentation (Deploy Runner guide)
├── README.md
└── [your-app/]        # Bootstrap here (e.g., Next.js)
```

**LocalStack Services**: SQS/S3/DynamoDB ready (add endpoints in `main.tf`).

**Registry**: localhost:5001 (push/pull images for ECR sim).

### GitLab CI/CD

This project includes GitLab CE with a **two-runner architecture**:

- **Build Runner** (DinD): Isolated image builds with Docker-in-Docker
- **Deploy Runner** (Host Docker): Deployments with access to devcontainer-network

See [Deploy Runner Documentation](docs/DEPLOY_RUNNER.md) for details.

**GitLab Management**:
```bash
./scripts/start-gitlab.sh      # Start GitLab containers
./scripts/setup-gitlab.sh      # Configure project + runners
./scripts/stop-gitlab.sh       # Stop GitLab (preserves data)
./scripts/stop-gitlab.sh --remove-data  # Stop and remove all data
```

**Pipeline Stages**: build_ci_images → validate → deploy_infra → deploy_app → build_backend → deploy_backend

## � Customize Terraform

1. Uncomment modules in `infrastructure/main.tf`.
2. Set vars (e.g., `terraform apply -var="queue_name=my-queue"`).
3. Outputs in `outputs.tf` / module outputs.

**Example SQS**:

```
module "my_sqs" {
  source = "./modules/sqs"
  queue_name = "my-app-queue"
  ...
}
```

## 🔧 Useful Commands

| Service | Command |
|---------|---------|
| **LocalStack** | `./scripts/start-localstack.sh` / `stop-localstack.sh` |
| **Registry** | `./scripts/start-supporting-services.sh` |
| **Terraform** | `cd infrastructure && terraform init && terraform plan` |
| **S3** | `awslocal s3 mb s3://my-bucket` |
| **SQS** | `awslocal sqs create-queue --queue-name my-queue` |
| **DynamoDB** | `awslocal dynamodb create-table --table-name my-table --attribute-definitions AttributeName=pk,AttributeType=S --key-schema AttributeName=pk,KeyType=HASH` |
| **Test** | `http GET localhost:4566/health` (httpie) |
| **GitLab** | `./scripts/setup-gitlab.sh` (setup), `http://localhost:8080` (access) |
| **GitLab Runners** | `docker exec gitlab-runner gitlab-runner list` (check runners) |
| **Docker dashboard** | `docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock -v /yourpath:/.config/jesseduffield/lazydocker lazyteam/lazydocker` <br><br> or to build it first: <br><br>`docker build -t lazyteam/lazydocker --build-arg BASE_IMAGE_BUILDER=arm64v8/golang --build-arg GOARCH=arm64 https://github.com/jesseduffield/lazydocker.git`|

## 🐛 Troubleshooting

- **LocalStack down**: `./scripts/start-localstack.sh --remove`
- **Ports conflict**: Kill on 4566/3000/5001.
- **Terraform state**: `rm infrastructure/terraform.tfstate*`
- **Rebuild devcontainer**: Cmd+Shift+P > "Dev Containers: Rebuild..."

## 📚 Technologies

- **Base**: Debian Bookworm + Node 20, Terraform latest.
- **LocalStack 3.x**, AWS CLI, awslocal.
- **dinD** (Buildx/Compose v2).

## 🎯 Use as Devcontainer Template

1. **GitHub Setup**:

   - Push this repo.
   - Repo Settings > **Template repository** > Save.

2. **VSCode**:

   - Cmd+Shift+P > "Dev Containers: Add Dev Container Configuration Files..."
   - Search "LocalStack" or your repo name.
   - Or clone template repo > Reopen in Container.

3. **Test**:
   ```
   npx @devcontainers/cli@latest up --workspace-folder .
   ```

See [containers.dev](https://containers.dev/) for more.

Fork & customize! 🚀
