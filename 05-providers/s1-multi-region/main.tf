data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_s3_bucket" "primary" {
  bucket_prefix = "tfadv-primary-"
  force_destroy = true
}

output "ami_ids" {
  value = { primary = data.aws_ami.al2023.id }
}

# TODO: us-west-2 provider, 리전별 AMI 조회, DR 버킷, 두 리전에 걸친 모듈
