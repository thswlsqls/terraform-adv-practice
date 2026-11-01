terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

resource "aws_s3_bucket" "logs" {
  bucket_prefix = "tfadv-logs-"
  force_destroy = true
}
