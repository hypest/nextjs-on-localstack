#!/bin/sh
set -e

# Docker entrypoint for S3 website proxy
# Sets up nginx configuration with the correct port

# Get port from environment or default
PROXY_PORT="${PROXY_PORT:-8888}"

echo "Starting S3 website proxy on port $PROXY_PORT"

# Substitute port in nginx config
envsubst '${PROXY_PORT}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Start nginx
exec nginx -g 'daemon off;'