resource "aws_security_group" "app" {
  name_prefix = "drift-app-"
  description = "app sg"

  # 인라인 ingress는 authoritative: 코드에 없는 22/tcp 규칙(미승인 드리프트)은 apply 때 제거된다.
  ingress {
    description = "https internal"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "drift-app"
    Owner = "security-team" # 승인된 드리프트는 코드에 반영한다
  }
}

resource "aws_s3_bucket" "artifacts" {
  bucket_prefix = "drift-artifacts-"
  force_destroy = true
}

# 삭제된 object는 코드가 그대로이므로 apply 때 다시 생성된다(미승인 드리프트 복구).
resource "aws_s3_object" "config" {
  bucket       = aws_s3_bucket.artifacts.id
  key          = "app/config.json"
  content      = jsonencode({ version = 1 })
  content_type = "application/json"
}

output "sg_id" {
  value = aws_security_group.app.id
}

output "bucket" {
  value = aws_s3_bucket.artifacts.id
}
