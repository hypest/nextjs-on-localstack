terraform {
  backend "s3" {
    bucket                      = "terraform-state-devcontainer-localstack"
    key                         = "terraform.tfstate"
    region                      = "us-east-1"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    use_path_style              = true
    # Use default AWS credentials (test/test for LocalStack)
    # Endpoint configured via AWS_ENDPOINT_URL environment variable
  }
}
