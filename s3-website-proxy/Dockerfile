FROM nginx:alpine

# Copy nginx configuration
COPY nginx.conf.template /etc/nginx/nginx.conf

# Expose port
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
