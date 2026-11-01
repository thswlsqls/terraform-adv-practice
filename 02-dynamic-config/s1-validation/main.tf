variable "env" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "allowed_cidr" {
  type    = string
  default = "10.0.0.0/8"
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*"]
  }
}

resource "aws_security_group" "web" {
  name_prefix = "val-web-"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.web.id]

  tags = {
    Name = "val-web-${var.env}"
  }
}
