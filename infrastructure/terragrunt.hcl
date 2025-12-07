# Terragrunt configuration for modular deployments
# Uses hooks to run additional deployment steps conditionally

terraform {
  source = "."

  # After terraform apply, conditionally deploy backend if EC2 module is present
  after_hook "deploy_backend" {
    commands = ["apply"]
    execute = ["bash", "-c", "if [ -d ../backend-api ] && terragrunt output ec2_instance_id >/dev/null 2>&1; then echo '🐳 Deploying backend API container...'; ../scripts/deploy-backend.sh $ENVIRONMENT; else echo 'ℹ️  Skipping backend deployment (EC2 not present or backend-api missing)'; fi"]
  }
}