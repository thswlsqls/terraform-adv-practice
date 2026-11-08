variable "buckets" {
  type    = list(string)
  default = ["raw", "curated"]
}

# 1. count 기반 aws_s3_bucket.b → for_each 기반 aws_s3_bucket.data
#    bucket_prefix 표현식 결과가 기존과 같아 moved 후 diff가 없다.
resource "aws_s3_bucket" "data" {
  for_each      = toset(var.buckets)
  bucket_prefix = "tfadv-${each.key}-"
  force_destroy = true
}

moved {
  from = aws_s3_bucket.b[0]
  to   = aws_s3_bucket.data["raw"]
}

moved {
  from = aws_s3_bucket.b[1]
  to   = aws_s3_bucket.data["curated"]
}

# 2. aws_s3_bucket.tmp 블록은 삭제했다.
#    Terraform 1.6에는 removed 블록(1.7+)이 없으므로, 블록 삭제와 함께
#    terraform state rm aws_s3_bucket.tmp 로 state에서만 제거한다(실제 버킷은 남는다).
