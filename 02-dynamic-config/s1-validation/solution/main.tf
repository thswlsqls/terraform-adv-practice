variable "env" {
  type = string

  validation {
    condition     = contains(["dev", "stg", "prod"], var.env)
    error_message = "env must be one of dev, stg, prod."
  }
}

variable "instance_type" {
  type    = string
  default = "t3.micro"

  validation {
    condition     = contains(["t3.micro", "t3.small"], var.instance_type)
    error_message = "instance_type must be t3.micro or t3.small."
  }
}

variable "allowed_cidr" {
  type    = string
  default = "10.0.0.0/8"

  validation {
    condition     = can(cidrnetmask(var.allowed_cidr))
    error_message = "allowed_cidr must be a valid IPv4 CIDR block."
  }
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  lifecycle {
    postcondition {
      condition     = self.architecture == "x86_64"
      error_message = "AMI must be x86_64 for t3 instance types."
    }
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

  lifecycle {
    # 1.6의 variable validation은 자기 변수만 참조 가능 → 변수 간 규칙은 precondition으로
    precondition {
      condition     = var.env != "prod" || var.instance_type == "t3.small"
      error_message = "prod must use t3.small."
    }
  }
}

check "web_running" {
  assert {
    condition     = aws_instance.web.instance_state == "running"
    error_message = "web instance is not running."
  }
}
