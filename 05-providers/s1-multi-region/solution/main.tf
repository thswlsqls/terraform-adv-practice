data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

data "aws_ami" "al2023_dr" {
  provider    = aws.dr
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

resource "aws_s3_bucket" "dr" {
  provider      = aws.dr
  bucket_prefix = "tfadv-dr-"
  force_destroy = true
}

module "reports" {
  source = "./modules/replicated-bucket"
  providers = {
    aws.src = aws
    aws.dst = aws.dr
  }

  name = "tfadv-reports"
}

output "ami_ids" {
  value = {
    primary = data.aws_ami.al2023.id
    dr      = data.aws_ami.al2023_dr.id
  }
}

output "report_buckets" {
  value = module.reports.buckets
}
