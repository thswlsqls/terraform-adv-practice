module "logs" {
  source = "./modules/logs"
}

resource "aws_s3_bucket" "audit" {
  provider      = aws.eu
  bucket_prefix = "tfadv-audit-"
  force_destroy = true
}
