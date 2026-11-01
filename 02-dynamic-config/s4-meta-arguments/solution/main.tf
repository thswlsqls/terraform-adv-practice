variable "sg_description" {
  type    = string
  default = "web tier"
}

variable "enable_bastion" {
  type    = bool
  default = false
}

variable "release" {
  type    = string
  default = "2026.10.1"
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

data "aws_subnets" "default" {
  # us-east-1e 등 일부 AZ는 t3 미지원 → a, b로 한정
  filter {
    name   = "availability-zone"
    values = ["${var.region}a", "${var.region}b"]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

resource "aws_security_group" "web" {
  name_prefix = "meta-web-"
  description = var.sg_description

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "http" {
  type              = "ingress"
  security_group_id = aws_security_group.web.id
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_launch_template" "web" {
  name_prefix            = "meta-web-"
  image_id               = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.web.id]
}

resource "aws_autoscaling_group" "web" {
  name_prefix         = "meta-web-"
  min_size            = 0
  max_size            = 2
  desired_capacity    = 0
  vpc_zone_identifier = data.aws_subnets.default.ids

  launch_template {
    id      = aws_launch_template.web.id
    version = aws_launch_template.web.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 0
    }
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

output "asg_name" {
  value = aws_autoscaling_group.web.name
}

resource "aws_s3_bucket" "audit" {
  bucket_prefix = "meta-audit-"
  force_destroy = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "terraform_data" "release" {
  input = var.release
}

resource "aws_instance" "bastion" {
  count = var.enable_bastion ? 1 : 0

  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.web.id]

  tags = {
    Name    = "meta-bastion"
    Release = var.release
  }

  lifecycle {
    replace_triggered_by = [terraform_data.release]
  }
}

output "bastion_id" {
  value = one(aws_instance.bastion[*].id)
}
