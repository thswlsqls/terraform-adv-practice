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
  name        = "meta-web"
  description = var.sg_description
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
}

output "asg_name" {
  value = aws_autoscaling_group.web.name
}

resource "aws_s3_bucket" "audit" {
  bucket_prefix = "meta-audit-"
  force_destroy = true
}

# TODO: bastion (enable_bastion), release 변경 시 bastion 교체, 출력 bastion_id
