resource "random_integer" "build" {
  min = 1
  max = 1000
}

resource "aws_s3_object" "marker" {
  bucket  = var.bucket
  key     = "markers/app-${random_integer.build.result}.txt"
  content = "build ${random_integer.build.result}"
}

variable "bucket" {
  type        = string
  description = "bootstrap output bucket (marker 저장용)"
}
