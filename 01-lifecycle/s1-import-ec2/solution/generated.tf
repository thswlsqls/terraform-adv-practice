# __generated__ by Terraform 에서 시작해 정리한 결과 (과제 3, 5 반영)
#
# 실제 생성 파일에는 computed 값까지 수십 개 인자가 들어 있다. 여기서는 채점에 필요한 인자만 남겼다.
# - Optional+Computed 인자(subnet_id, private_ip, ebs_optimized 등)는 지워도 diff가 생기지 않는다.
# - ami는 지울 수 없다(ami/launch_template 중 하나 필수). 생성된 실제 값을 그대로 두어야 교체가 일어나지 않는다.

resource "aws_security_group" "legacy" {
  name        = "legacy-web-sg"
  description = "legacy web"

  # 인라인 ingress/egress는 SG 규칙 전체를 authoritative하게 관리한다.
  # setup.sh가 만든 80/tcp 규칙과 AWS 기본 egress 규칙을 그대로 옮긴다.
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    description      = ""
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    description      = ""
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }

  # Project 태그는 provider default_tags가 붙인다.
  tags = {
    ManagedBy = "terraform"
  }
}

resource "aws_instance" "legacy" {
  ami           = "ami-0123456789abcdef0" # ← 본인 generated.tf에 생성된 실제 AMI ID를 그대로 둘 것 (ForceNew)
  instance_type = "t3.micro"

  # 하드코딩된 ["sg-..."] 대신 참조로 교체: 의존성이 생기고 ID가 코드에서 사라진다.
  vpc_security_group_ids = [aws_security_group.legacy.id]

  tags = {
    Name      = "legacy-web"
    ManagedBy = "terraform"
  }
}
