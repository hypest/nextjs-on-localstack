locals {
  # S3 bucket names must be <= 63 characters
  # If full name exceeds limit, truncate environment and add hash suffix
  full_bucket_name = "${var.bucket_name}-${var.environment}-${var.infra_name}"
  bucket_name_length = length(local.full_bucket_name)
  
  # Create short hash of environment if needed
  env_hash = substr(md5(var.environment), 0, 8)
  
  # Use full name if under limit, otherwise use truncated version with hash
  final_bucket_name = local.bucket_name_length <= 63 ? local.full_bucket_name : "${var.bucket_name}-${local.env_hash}-${var.infra_name}"
}

resource "aws_s3_bucket" "this" {
  bucket        = local.final_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_website_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "404.html"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id

  depends_on = [aws_s3_bucket_public_access_block.this]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.this.arn}/*"
      },
    ]
  })
}
