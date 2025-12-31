FROM nginx:alpine

# Copy nginx configuration template
COPY nginx.conf.template /etc/nginx/nginx.conf.template

# Copy entrypoint script
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Expose port (will be set by entrypoint)
EXPOSE 8888

# Use custom entrypoint
ENTRYPOINT ["/docker-entrypoint.sh"]