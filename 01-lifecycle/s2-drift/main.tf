resource "aws_security_group" "app" {
  name_prefix = "drift-app-"
  description = "app sg"

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
    Owner = "platform"
  }
}

resource "aws_s3_bucket" "artifacts" {
  bucket_prefix = "drift-artifacts-"
  force_destroy = true
}

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
