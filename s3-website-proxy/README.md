# S3 Website Proxy (Standalone Docker - DEPRECATED)

⚠️ **This directory contains a deprecated standalone Docker approach.**

## Current Implementation

The S3 website proxy is now deployed as **infrastructure via Terraform** in the `infrastructure/modules/s3-website-proxy/` module. This approach:

- ✅ Deploys as an EC2 instance in LocalStack (more realistic)
- ✅ Uses dynamic port mapping per environment
- ✅ Integrates with infrastructure-as-code workflow
- ✅ Can be destroyed/recreated with `deploy-infra.sh`/`destroy-infra.sh`

## Why This Proxy Exists

GitHub Codespaces port forwarding doesn't support virtual-host routing (subdomain-based). LocalStack's S3 static website hosting uses URLs like:

```
http://{bucket}.s3-website.us-east-1.localhost.localstack.cloud:4566/
```

Through Codespaces, you only get:
```
https://{codespace-name}-4566.app.github.dev/
```

This hits the S3 **API endpoint** (returns XML), not the **website endpoint** (returns HTML).

## The Solution

The proxy translates path-style URLs to virtual-host URLs:

**Input:** `https://...-8888.app.github.dev/my-bucket/index.html`

**Proxy sets:** `Host: my-bucket.s3-website.us-east-1.localhost.localstack.cloud`

**LocalStack returns:** The actual website content (HTML, JS, CSS)

## Usage

The proxy is automatically deployed when you run:

```bash
./scripts/deploy-infra.sh <environment>
```

Access your Next.js app at the URL shown in the deploy output.

## Files in This Directory

These files are kept for reference but not used:
- `Dockerfile` - Standalone nginx container
- `nginx.conf.template` - Similar config to what's in the Terraform module

The actual implementation is in:
- `infrastructure/modules/s3-website-proxy/` - Terraform module
- `infrastructure/modules/s3-website-proxy/user-data.sh` - nginx setup script for EC2
