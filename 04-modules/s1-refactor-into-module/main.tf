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

resource "aws_security_group" "web" {
  name_prefix = "mono-web-"
  vpc_id      = data.aws_subnet.a.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.web.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnet.a.id
  vpc_security_group_ids = [aws_security_group.web.id]

  tags = {
    Name = "web-blue"
  }
}

output "web_public_ip" {
  value = aws_instance.web.public_ip
}
