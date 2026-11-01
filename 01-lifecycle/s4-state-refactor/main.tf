variable "buckets" {
  type    = list(string)
  default = ["raw", "curated"]
}

resource "aws_s3_bucket" "b" {
  count         = length(var.buckets)
  bucket_prefix = "tfadv-${var.buckets[count.index]}-"
  force_destroy = true
}

resource "aws_s3_bucket" "tmp" {
  bucket_prefix = "tfadv-tmp-"
  force_destroy = true
}
