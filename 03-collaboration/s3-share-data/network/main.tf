terraform {
  backend "s3" {
    key = "network/terraform.tfstate"
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  # us-east-1e 등 일부 AZ는 t3 미지원 → a, b로 한정
  filter {
    name   = "availability-zone"
    values = ["${var.region}a", "${var.region}b"]
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "app" {
  name_prefix = "share-app-"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "share-app"
    Tier = "app"
  }
}

output "vpc_id" {
  value = data.aws_vpc.default.id
}

output "subnet_ids" {
  value = sort(data.aws_subnets.default.ids)
}

output "app_sg_id" {
  value = aws_security_group.app.id
}
