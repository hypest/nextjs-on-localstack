resource "aws_security_group" "api_sg" {
  name        = "${var.infra_name}-api-sg-${var.environment}"
  description = "Security group for backend API server"

  ingress {
    description = "API port"
    from_port   = var.api_port
    to_port     = var.api_port
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
    Name        = "${var.infra_name}-api-sg-${var.environment}"
    Environment = var.environment
    Project     = var.infra_name
  }
}

resource "aws_instance" "api_server" {
  ami           = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.api_sg.id]

  user_data = file("${path.module}/user-data.sh")

  tags = {
    Name        = "${var.infra_name}-api-${var.environment}"
    Environment = var.environment
    Project     = var.infra_name
  }
}
