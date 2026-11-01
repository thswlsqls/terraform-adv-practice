terraform {
  backend "s3" {
    key = "share-app/terraform.tfstate"
  }
}

variable "state_bucket" {
  type = string
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# TODO: network state 읽기, workspace별 instance_type, aws_instance.app
