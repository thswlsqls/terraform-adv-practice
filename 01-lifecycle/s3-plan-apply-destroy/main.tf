resource "random_integer" "suffix" {
  min = 10000
  max = 99999
}

resource "aws_s3_bucket" "logs" {
  bucket        = "tfadv-logs-${random_integer.suffix.result}"
  force_destroy = true
}

variable "reports" {
  type    = list(string)
  default = ["daily", "weekly", "monthly"]
}

resource "aws_s3_object" "report" {
  count   = length(var.reports)
  bucket  = aws_s3_bucket.logs.id
  key     = "reports/${var.reports[count.index]}.txt"
  content = "report: ${var.reports[count.index]}"
}
