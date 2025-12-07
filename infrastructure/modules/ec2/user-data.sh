#!/bin/bash
set -euo pipefail

# EC2 User Data Script - Install and run backend API container
# This script would run on real AWS EC2 instances during bootstrap

echo "Starting EC2 bootstrap for backend API..."

# Install Docker (on Ubuntu - adjust for Amazon Linux if needed)
apt-get update
apt-get install -y docker.io curl

# Start Docker service
service docker start

# Login to local Docker registry (for LocalStack development)
echo "Logging into local Docker registry..."
docker login localhost:5001 --username test --password test

# Pull and run the backend API container
echo "Pulling and starting backend API container..."
docker run -d \
  --name backend-api \
  --restart unless-stopped \
  -p 3001:3001 \
  -e NODE_ENV=production \
  -e EC2_INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id || echo "local-instance") \
  localhost:5001/backend-api:latest

echo "Backend API container started successfully!"
echo "API available at: http://localhost:3001/api/status"
