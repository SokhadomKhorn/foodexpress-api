provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "sg" {
  name = "allow_web"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app" {
  ami           = "ami-0ec10929233384c7f"   # Ubuntu (from your PDF)
  instance_type = "t3.micro"
  key_name      = "foodexpress"

  vpc_security_group_ids = [aws_security_group.sg.id]

  tags = {
    Name = "foodexpress"
  }
}
