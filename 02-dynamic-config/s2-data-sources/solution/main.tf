data "aws_caller_identity" "current" {}

data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_subnet" "app" {
  availability_zone = data.aws_availability_zones.available.names[0]
  default_for_az    = true
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

locals {
  account_id      = data.aws_caller_identity.current.account_id
  artifact_bucket = "tfadv-artifacts-${local.account_id}"
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "read_artifacts" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${local.artifact_bucket}"]
  }

  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${local.artifact_bucket}/*"]
  }
}

resource "aws_iam_role" "app" {
  name               = "tfadv-app-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_policy" "read_artifacts" {
  name   = "tfadv-read-artifacts"
  policy = data.aws_iam_policy_document.read_artifacts.json
}

resource "aws_iam_role_policy_attachment" "read_artifacts" {
  role       = aws_iam_role.app.name
  policy_arn = aws_iam_policy.read_artifacts.arn
}

resource "aws_iam_instance_profile" "app" {
  name = "tfadv-app-profile"
  role = aws_iam_role.app.name
}

resource "aws_instance" "app" {
  ami                  = data.aws_ami.al2023.id
  instance_type        = "t3.micro"
  subnet_id            = data.aws_subnet.app.id
  iam_instance_profile = aws_iam_instance_profile.app.name

  # instance profile → role 참조는 있지만 policy attachment와의 순서는 보장되지 않음
  depends_on = [aws_iam_role_policy_attachment.read_artifacts]

  tags = {
    Name = "tfadv-app"
  }
}

output "deployer_issuer_arn" {
  value = data.aws_iam_session_context.current.issuer_arn
}

output "app_subnet" {
  value = {
    id   = data.aws_subnet.app.id
    az   = data.aws_subnet.app.availability_zone
    cidr = data.aws_subnet.app.cidr_block
  }
}
