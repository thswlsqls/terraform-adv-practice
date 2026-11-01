variable "env" {
  type    = string
  default = "dev"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "default_tags" {
  type    = map(string)
  default = { Team = "platform", Env = "unknown" }
}

variable "instance_type_by_env" {
  type    = map(string)
  default = { prod = "t3.small" }
}

variable "egress" {
  type = list(object({
    port        = number
    cidr_blocks = list(string)
    description = optional(string, "managed by terraform")
  }))
  default = [
    { port = 443, cidr_blocks = ["0.0.0.0/0"] },
    { port = 5432, cidr_blocks = ["10.20.0.0/16"], description = "postgres" },
  ]
}

locals {
  rules         = { for r in csvdecode(file("${path.module}/rules.csv")) : r.name => r }
  tags          = merge(var.default_tags, { Env = var.env })
  instance_type = lookup(var.instance_type_by_env, var.env, "t3.micro")
  subnet_cidrs  = [for i in range(4) : cidrsubnet(var.vpc_cidr, 4, i)]
}

resource "aws_security_group" "app" {
  name_prefix = "expr-app-"
  tags        = local.tags

  dynamic "egress" {
    for_each = var.egress
    content {
      description = egress.value.description
      from_port   = egress.value.port
      to_port     = egress.value.port
      protocol    = "tcp"
      cidr_blocks = egress.value.cidr_blocks
    }
  }
}

resource "aws_vpc_security_group_ingress_rule" "app" {
  for_each = local.rules

  security_group_id = aws_security_group.app.id
  description       = each.key
  ip_protocol       = "tcp"
  from_port         = tonumber(each.value.port)
  to_port           = tonumber(each.value.port)
  cidr_ipv4         = each.value.cidr
  tags              = local.tags
}

output "rules" {
  value = { for k, r in aws_vpc_security_group_ingress_rule.app : k => { port = r.from_port, cidr = r.cidr_ipv4 } }
}

output "public_rules" {
  value = sort([for r in local.rules : r.name if r.public == "true"])
}

output "instance_type" {
  value = local.instance_type
}

output "subnet_cidrs" {
  value = local.subnet_cidrs
}

output "user_data" {
  value = templatefile("${path.module}/user_data.tftpl", {
    env   = var.env
    ports = sort([for r in local.rules : r.port])
  })
}
