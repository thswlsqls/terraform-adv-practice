data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

data "aws_subnet" "a" {
  availability_zone = "${var.region}a"
  default_for_az    = true
}

locals {
  web = {
    blue  = { instance_type = "t3.micro", sg_name_prefix = "mono-web-" }
    green = { instance_type = "t3.micro", sg_name_prefix = null }
  }
}

module "web" {
  source   = "./modules/web-server"
  for_each = local.web

  name           = "web-${each.key}"
  subnet_id      = data.aws_subnet.a.id
  ami_id         = data.aws_ami.al2023.id
  instance_type  = each.value.instance_type
  sg_name_prefix = each.value.sg_name_prefix
}

# 1차 리팩터링(모놀리스 → 모듈)과 2차(module.web → module.web["blue"])를 한 번에 표현
moved {
  from = aws_security_group.web
  to   = module.web["blue"].aws_security_group.this
}

moved {
  from = aws_vpc_security_group_ingress_rule.http
  to   = module.web["blue"].aws_vpc_security_group_ingress_rule.this["80"]
}

moved {
  from = aws_instance.web
  to   = module.web["blue"].aws_instance.this
}

output "web_public_ips" {
  value = { for k, m in module.web : k => m.public_ip }
}
