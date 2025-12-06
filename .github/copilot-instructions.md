# Codebase Overview

## Project Purpose

This is a **LocalStack-based development environment** for deploying Next.js static sites to S3 using Terraform. It simulates AWS infrastructure locally, enabling developers to test infrastructure-as-code and deployment workflows without cloud costs. The project demonstrates multi-environment deployments (prod, staging, feature branches) with full automation.

## Architecture

### Core Components

1. **Next.js Application** (`hello-nextjs/`)

   - Static-export Next.js app (v14.2.3)
   - Configured for S3 static hosting with `output: "export"` and unoptimized images
   - Single page app with a Hello World home page
   - Builds to `out/` directory for deployment

2. **Infrastructure as Code** (`infrastructure/`)

   - Terraform configuration targeting LocalStack endpoints
   - Uses AWS provider with hardcoded test credentials and `s3_use_path_style: true`
   - Module-based architecture with reusable S3, SQS components
   - Workspace-based environment isolation (prod, staging, feature branches)

3. **Reusable Terraform Modules** (`modules/`)

   - `s3/`: Creates S3 buckets with static website hosting, public access, and website configuration
   - `sqs/`: Creates SQS queues with DLQ (dead letter queue) support

4. **Deployment Scripts** (`scripts/`)

   - `setup.sh`: Full environment bootstrap (Terraform init, LocalStack start, registry start)
   - `deploy-infra.sh`: Provisions infrastructure for an environment using Terraform workspaces
   - `deploy-app.sh`: Builds Next.js app and uploads to S3 using Python/boto3
   - `destroy-infra.sh`: Tears down infrastructure for an environment
   - `start-localstack.sh`: Starts LocalStack container with Docker-in-Docker
   - `start-supporting-services.sh`: Starts Docker registry for ECR simulation
   - `stop-localstack.sh`: Stops LocalStack container

5. **Python Deployment Tool** (`deploy-nextjs.py`)

   - Uses boto3 to upload Next.js build artifacts to S3
   - Clears old files before upload (simulates `--delete`)
   - Sets proper Content-Type headers for HTML, JS, CSS, JSON, and image files
   - Targets LocalStack S3 endpoint at localhost:4566

6. **Git Automation** (`git-hooks/`)
   - `post-commit`: Auto-deploys infrastructure and app on commits to `production` (→ prod) or `develop` (→ staging) branches
   - Other branches require manual deployment

## Key Patterns & Conventions

### Environment Management

- Environments are passed as strings (e.g., `prod`, `staging`, `feature/mybranch`)
- Branch names with slashes/spaces are sanitized to Terraform workspace names (e.g., `feature/mybranch` → `feature-mybranch`)
- S3 bucket naming: `{bucket_base_name}-{environment}-{project_name}` (e.g., `hello-nextjs-prod-devcontainer-localstack`)

### LocalStack Configuration

- All AWS endpoints point to `http://localhost:4566`
- Credentials are hardcoded as `test`/`test` (only works with LocalStack)
- S3 uses path-style URLs (required for LocalStack)
- Website URLs follow pattern: `http://{bucket}.s3-website.us-east-1.localhost.localstack.cloud:4566/`

### Infrastructure Organization

- `infrastructure/`: Main Terraform root with provider config and module invocations
- `modules/`: Shared, reusable Terraform modules for different AWS services
- `infrastructure/modules/`: Additional SQS module (note: duplicates `modules/sqs/`)
- Terraform state is isolated per workspace in `terraform.tfstate.d/{workspace}/`

### Deployment Workflow

1. Deploy infrastructure: `./scripts/deploy-infra.sh <env>` → creates/updates S3 bucket
2. Build and deploy app: `./scripts/deploy-app.sh <env>` → builds Next.js, uploads to S3
3. Access website at the output URL (LocalStack S3 website endpoint)

### Docker-in-Docker Setup

- Dev container runs Docker daemon internally
- LocalStack runs as a container managed from within the dev container
- Docker registry (port 5001) simulates AWS ECR for local development
- Uses custom network `devcontainer-network` and persistent volume `devcontainer_local_registry_data`

## Project State

- **Active Infrastructure**: Module for Next.js S3 hosting is active in `infrastructure/main.tf`
- **Commented Examples**: SQS, DynamoDB module invocations are commented out as templates
- **Current App**: Basic single-page Next.js app with minimal content
- **Terraform State**: `prod` workspace exists with state in `infrastructure/terraform.tfstate.d/prod/`

## Development Workflow

### To Add a New Feature

1. Create a feature branch: `git checkout -b feature/my-feature`
2. Deploy dedicated environment: `./scripts/deploy-infra.sh "feature/my-feature"`
3. Make changes to `hello-nextjs/`
4. Deploy app: `./scripts/deploy-app.sh "feature/my-feature"`
5. Test at the output S3 website URL
6. Destroy when done: `./scripts/destroy-infra.sh "feature/my-feature"`

### To Add New AWS Services

1. Create a module in `modules/{service}/` (or use existing templates)
2. Add module invocation in `infrastructure/main.tf`
3. Add outputs in `infrastructure/outputs.tf`
4. Run `./scripts/deploy-infra.sh <env>` to provision

### To Modify the Next.js App

- Edit files in `hello-nextjs/pages/` (add new pages/components)
- Update `package.json` for new dependencies
- Redeploy: `./scripts/deploy-app.sh <env>`

## Important Notes

- This is a **local development environment only** - not for production AWS
- All infrastructure is ephemeral (destroyed when LocalStack container stops unless persistence is enabled)
- Python deployment script has hardcoded path to `/workspaces/experimental-nextjs-app/hello-nextjs/out`
- No authentication/security - everything is public by design for local testing
- Legacy files present: `deploy-nextjs.sh`, `bucket-policy.json`, `website-config.json` (unused, replaced by Python script and Terraform)

## Troubleshooting

- If LocalStack isn't running: `./scripts/start-localstack.sh`
- If Terraform fails: Check LocalStack is running and endpoints are accessible
- If deployment fails: Verify bucket exists with `awslocal s3 ls` or check Terraform outputs
- For "bucket doesn't exist" errors: Run `./scripts/deploy-infra.sh <env>` first

## Tech Stack

- **Frontend**: Next.js 14.2.3, React 18.3.1
- **Infrastructure**: Terraform with AWS provider ~> 5.0
- **Local Cloud**: LocalStack (S3, SQS, DynamoDB endpoints)
- **Deployment**: Python 3 with boto3
- **Container Runtime**: Docker-in-Docker
- **Shell**: Bash scripts with `set -euo pipefail` (strict mode)
