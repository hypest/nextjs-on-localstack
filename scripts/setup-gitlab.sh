#!/bin/bash
set -euo pipefail

# Script to set up local GitLab CI/CD environment
# This automates the creation of a GitLab project and SSH key setup

GITLAB_URL="http://localhost:8080"
GITLAB_API_URL="${GITLAB_URL}/api/v4"
PROJECT_NAME="nextjs-on-localstack"
SSH_KEY_PATH="${HOME}/.ssh/id_ed25519_gitlab"

echo "🚀 Setting up local GitLab CI/CD environment..."

# Check if GitLab is running
echo "📡 Checking if GitLab is accessible..."
for i in {1..120}; do
    if curl -s --max-time 5 "${GITLAB_URL}" > /dev/null; then
        break
    fi
    echo "Waiting for GitLab web interface... (${i}/120)"
    sleep 5
done

if ! curl -s --max-time 5 "${GITLAB_URL}" > /dev/null; then
    echo "❌ GitLab web interface is not accessible after 10 minutes"
    exit 1
fi

echo "✅ GitLab web interface is accessible!"

# Wait for GitLab to be fully ready
echo "⏳ Waiting for GitLab to be ready..."
for i in {1..60}; do
    if curl -s "${GITLAB_API_URL}/version" > /dev/null; then
        break
    fi
    echo "Waiting... (${i}/60)"
    sleep 5
done

if ! curl -s "${GITLAB_API_URL}/version" > /dev/null; then
    echo "❌ GitLab API is not ready after 5 minutes"
    exit 1
fi

echo "✅ GitLab is ready!"

# Generate SSH key if it doesn't exist
if [ ! -f "${SSH_KEY_PATH}" ]; then
    echo "🔑 Generating SSH key..."
    ssh-keygen -t ed25519 -C "gitlab-local" -f "${SSH_KEY_PATH}" -N ""
else
    echo "🔑 SSH key already exists at ${SSH_KEY_PATH}"
fi

# Get the public key
SSH_PUBLIC_KEY=$(cat "${SSH_KEY_PATH}.pub")

# Configure SSH client to use the key for GitLab
SSH_CONFIG="${HOME}/.ssh/config"
if [ ! -f "${SSH_CONFIG}" ]; then
    touch "${SSH_CONFIG}"
fi
if ! grep -q "Host localhost" "${SSH_CONFIG}"; then
    echo "🔧 Configuring SSH for GitLab..."
    cat >> "${SSH_CONFIG}" << EOF
Host localhost
    HostName localhost
    Port 2222
    User git
    IdentityFile ${SSH_KEY_PATH}
EOF
fi

# Set up GitLab project and SSH key using Rails console
echo "🔧 Setting up GitLab project and SSH key..."

# Create the project
echo "📁 Creating project..."
export PROJECT_NAME="${PROJECT_NAME}"
docker exec -e PROJECT_NAME gitlab gitlab-rails runner "
user = User.find_by_username('root')
organization = Organizations::Organization.first
namespace = user.namespace
namespace.organization = organization
namespace.save
project = Project.find_by_path(ENV['PROJECT_NAME']) || Project.new(
  name: ENV['PROJECT_NAME'],
  path: ENV['PROJECT_NAME'],
  namespace: namespace,
  creator: user,
  organization: organization,
  visibility_level: 0
)
if project.save
  puts \"Project ready with ID: #{project.id}\"
  # Initialize the repository
  unless project.repository.exists?
    project.repository.create_repository
    puts \"Repository initialized\"
  end
else
  puts \"Failed to create project: #{project.errors.full_messages.join(', ')}\"
end
"

# Add SSH key
echo "🔑 Adding SSH key..."
export SSH_PUBLIC_KEY="${SSH_PUBLIC_KEY}"
docker exec -e SSH_PUBLIC_KEY gitlab gitlab-rails runner "
user = User.find_by_username('root')
key_content = ENV['SSH_PUBLIC_KEY']
existing_key = user.keys.find_by_key(key_content)
if existing_key
  puts 'SSH key already exists'
else
  key = user.keys.create(title: 'Local Dev SSH Key', key: key_content)
  puts \"SSH key added with ID: #{key.id}\"
end
" 2>/dev/null || echo "Failed to add SSH key"

# Set up Git remote
SSH_URL="ssh://git@localhost:2222/root/${PROJECT_NAME}.git"
echo "🔗 Setting up Git remote 'gitlab' to: ${SSH_URL}"

if git remote | grep -q "^gitlab$"; then
    git remote set-url gitlab "${SSH_URL}"
else
    git remote add gitlab "${SSH_URL}"
fi

echo "✅ GitLab CI/CD setup complete!"
echo ""
echo "📋 Summary:"
echo "   - SSH key: ${SSH_KEY_PATH}"
echo "   - GitLab project: ${PROJECT_NAME}"
echo "   - Git remote: gitlab -> ${SSH_URL}"
echo ""
echo "🚀 You can now push to GitLab with: git push gitlab <branch>"
echo "🔍 View your project at: ${GITLAB_URL}/root/${PROJECT_NAME}"