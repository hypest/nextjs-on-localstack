#!/bin/bash
set -euo pipefail

# Update system
apt-get update
apt-get install -y curl

# Install Node.js 18.x
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Create app directory
mkdir -p /home/ubuntu/backend-api
cd /home/ubuntu/backend-api

# Copy application files (these would be deployed separately in production)
# For LocalStack testing, we'll package them in the AMI or use a simple deployment method

# Get instance ID from metadata service (LocalStack simulates this)
export INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id || echo "local-instance")

# Start the application
# Note: In production, you'd use systemd or pm2 for process management
nohup node /home/ubuntu/backend-api/server.js > /var/log/api.log 2>&1 &
