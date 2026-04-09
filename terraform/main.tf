# ── Provider ──────────────────────────────────────────────────────
terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ── Variables ─────────────────────────────────────────────────────
variable "aws_region" {
  description = "AWS region to deploy to"
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the existing AWS key pair for SSH access"
  default     = "foodexpress-key"
}

variable "docker_image" {
  description = "Docker Hub image to deploy"
  default     = "sokhadomkhorn/foodexpress-api:latest"
}

# ── Latest Ubuntu 22.04 LTS AMI ───────────────────────────────────
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ── Security Group ─────────────────────────────────────────────────
resource "aws_security_group" "foodexpress_sg" {
  name        = "foodexpress-sg"
  description = "Allow HTTP and SSH for FoodExpress"

  ingress {
    description = "SSH for Jenkins deployment"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP public access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "App direct port"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "foodexpress-sg"
    Project = "FoodExpress"
  }
}

# ── EC2 Instance ───────────────────────────────────────────────────
resource "aws_instance" "foodexpress_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.foodexpress_sg.id]

  # User data: install Docker on first boot and run the container
  user_data = <<-EOF
    #!/bin/bash
    set -e

    apt-get update -y
    apt-get install -y ca-certificates curl gnupg

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
      | tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io

    systemctl enable docker
    systemctl start docker
    usermod -aG docker ubuntu


    echo "FoodExpress deployment complete."
  EOF

  tags = {
    Name        = "foodexpress-server"
    Project     = "FoodExpress"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# ── Outputs ────────────────────────────────────────────────────────
output "instance_id" {
  value = aws_instance.foodexpress_server.id
}

output "public_ip" {
  description = "EC2 Public IP — used by Jenkins for SSH deployment"
  value       = aws_instance.foodexpress_server.public_ip
}

output "app_url" {
  description = "FoodExpress live URL"
  value       = "http://${aws_instance.foodexpress_server.public_ip}"
}
