variable "db_password" {
  type = string
}

variable "service_tokens" {
  type      = map(string)
  sensitive = true
  default = {
    billing  = "tok-billing-123"
    shipping = "tok-shipping-456"
  }
}

resource "aws_s3_bucket" "config" {
  bucket_prefix = "sens-config-"
  force_destroy = true
}

resource "random_password" "api_key" {
  length  = 32
  special = false
}

resource "aws_s3_object" "app_env" {
  bucket  = aws_s3_bucket.config.id
  key     = "app.env"
  content = "DB_PASSWORD=${var.db_password}\nAPI_KEY=${random_password.api_key.result}\n"
}

resource "aws_s3_object" "token" {
  for_each = var.service_tokens

  bucket  = aws_s3_bucket.config.id
  key     = "tokens/${each.key}"
  content = each.value
}

output "api_key" {
  value = random_password.api_key.result
}
