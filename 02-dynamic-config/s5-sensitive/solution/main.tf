variable "db_password" {
  type      = string
  sensitive = true
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
  # 키(서비스 이름)는 비밀이 아니므로 키 집합만 nonsensitive로 풀고, 값은 sensitive 유지
  for_each = nonsensitive(toset(keys(var.service_tokens)))

  bucket  = aws_s3_bucket.config.id
  key     = "tokens/${each.key}"
  content = var.service_tokens[each.key]
}

output "api_key" {
  value     = random_password.api_key.result
  sensitive = true
}
