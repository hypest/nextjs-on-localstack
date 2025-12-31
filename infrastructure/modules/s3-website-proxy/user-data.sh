#!/bin/bash
set -euo pipefail

# EC2 User Data Script - Install and run S3 website proxy
# This proxy translates path-style URLs to virtual-host URLs for LocalStack S3 websites

echo "Starting EC2 bootstrap for S3 website proxy..."

# Install nginx
apt-get update
apt-get install -y nginx curl

# Create nginx configuration for S3 website proxy
cat > /etc/nginx/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Log format
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log warn;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;

    server {
        listen ${proxy_port};
        server_name _;

        # Proxy to LocalStack S3 website endpoint
        # Supports path-style URLs: /{bucket-name}/{path}
        location ~ ^/([^/]+)(/.*)?$ {
            set $bucket_name $1;
            set $object_path $2;
            
            # Rewrite to remove bucket name from path
            rewrite ^/[^/]+(.*)$ $1 break;
            
            # Set the Host header for LocalStack's virtual-host routing
            proxy_set_header Host $bucket_name.s3-website.us-east-1.localhost.localstack.cloud;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # Proxy to LocalStack (from within EC2 instance)
            # Use LocalStack's internal hostname
            proxy_pass http://localstack:4566;
            
            # Handle redirects
            proxy_redirect off;
            
            # Error handling
            proxy_intercept_errors on;
        }
        
        # Root path - return info message
        location = / {
            default_type text/html;
            return 200 '<html><body><h1>S3 Website Proxy</h1><p>Usage: /{bucket-name}/path</p></body></html>\n';
        }
        
        # Health check endpoint
        location /health {
            access_log off;
            return 200 "OK\n";
            add_header Content-Type text/plain;
        }
    }
}
EOF

# Start nginx
systemctl enable nginx
systemctl restart nginx

echo "S3 website proxy started successfully!"
echo "Proxy available at: http://localhost:${proxy_port}"
echo "Usage: http://localhost:${proxy_port}/{bucket-name}/"
