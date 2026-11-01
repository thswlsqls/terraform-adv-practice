data "aws_subnet" "this" {
  id = var.subnet_id
}

resource "aws_security_group" "this" {
  name_prefix = coalesce(var.sg_name_prefix, "${var.name}-")
  vpc_id      = data.aws_subnet.this.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = { for p in var.ingress_ports : tostring(p) => p }

  security_group_id = aws_security_group.this.id
  ip_protocol       = "tcp"
  from_port         = each.value
  to_port           = each.value
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.this.id]

  tags = {
    Name = var.name
  }
}
