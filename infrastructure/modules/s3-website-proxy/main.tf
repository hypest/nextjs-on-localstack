resource "aws_security_group" "proxy_sg" {
  name        = "${var.infra_name}-sg-${var.environment}"
  description = "Security group for S3 website proxy"

  ingress {
    description = "Proxy HTTP port"
    from_port   = var.proxy_port
    to_port     = var.proxy_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.infra_name}-sg-${var.environment}"
    Environment = var.environment
    Project     = var.infra_name
  }
}

resource "aws_instance" "proxy_server" {
  ami           = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.proxy_sg.id]

  user_data = templatefile("${path.module}/user-data.sh", {
    proxy_port = var.proxy_port
  })

  tags = {
    Name        = "${var.infra_name}-${var.environment}"
    Environment = var.environment
    Project     = var.infra_name
  }
}
