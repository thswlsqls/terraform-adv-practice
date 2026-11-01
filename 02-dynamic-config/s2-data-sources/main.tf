# 다른 계정·리전에서 복사해 온 코드 — 하드코딩 투성이
resource "aws_iam_role" "app" {
  name = "tfadv-app-role"

  assume_role_policy = <<-JSON
    {
      "Version": "2012-10-17",
      "Statement": [{
        "Effect": "Allow",
        "Principal": { "Service": "ec2.amazonaws.com" },
        "Action": "sts:AssumeRole"
      }]
    }
  JSON
}

resource "aws_iam_policy" "read_artifacts" {
  name = "tfadv-read-artifacts"

  policy = <<-JSON
    {
      "Version": "2012-10-17",
      "Statement": [{
        "Effect": "Allow",
        "Action": ["s3:GetObject", "s3:ListBucket"],
        "Resource": [
          "arn:aws:s3:::tfadv-artifacts-111122223333",
          "arn:aws:s3:::tfadv-artifacts-111122223333/*"
        ]
      }]
    }
  JSON
}

resource "aws_instance" "app" {
  ami           = "ami-0123456789abcdef0"
  instance_type = "t3.micro"
  subnet_id     = "subnet-0123456789abcdef0"

  tags = {
    Name = "tfadv-app"
  }
}
