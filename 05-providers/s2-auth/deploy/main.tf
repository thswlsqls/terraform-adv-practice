resource "aws_s3_bucket" "deploy" {
  bucket_prefix = "tfadv-deploy-"
  force_destroy = true
}

resource "aws_s3_bucket" "forbidden" {
  count         = var.try_forbidden ? 1 : 0
  bucket_prefix = "tfadv-other-"
}

variable "try_forbidden" {
  type    = bool
  default = false
}

# TODO: 실행 주체 확인 출력 (caller_arn, issuer_arn)
