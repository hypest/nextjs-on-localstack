terraform {
  backend "s3" {
    bucket = "terraform-state-${var.project_name}"
    key    = "terraform.tfstate"
    region = "us-east-1"
    endpoints = {
      s3 = "http://host.docker.internal:4566"
    }
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    use_path_style              = true
    # Use default AWS credentials (test/test for LocalStack)
  }
}
