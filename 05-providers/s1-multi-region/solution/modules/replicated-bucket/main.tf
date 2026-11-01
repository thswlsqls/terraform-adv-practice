terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 5.0"
      configuration_aliases = [aws.src, aws.dst]
    }
  }
}

variable "name" {
  type = string
}

resource "aws_s3_bucket" "src" {
  provider      = aws.src
  bucket_prefix = "${var.name}-src-"
  force_destroy = true
}

resource "aws_s3_bucket" "dst" {
  provider      = aws.dst
  bucket_prefix = "${var.name}-dst-"
  force_destroy = true
}

# 복제는 양쪽 버킷 모두 versioning이 켜져 있어야 한다
resource "aws_s3_bucket_versioning" "src" {
  provider = aws.src
  bucket   = aws_s3_bucket.src.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "dst" {
  provider = aws.dst
  bucket   = aws_s3_bucket.dst.id
  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_iam_policy_document" "assume" {
  provider = aws.src

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "replication" {
  provider = aws.src

  statement {
    actions   = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
    resources = [aws_s3_bucket.src.arn]
  }

  statement {
    actions   = ["s3:GetObjectVersionForReplication", "s3:GetObjectVersionAcl", "s3:GetObjectVersionTagging"]
    resources = ["${aws_s3_bucket.src.arn}/*"]
  }

  statement {
    actions   = ["s3:ReplicateObject", "s3:ReplicateDelete", "s3:ReplicateTags"]
    resources = ["${aws_s3_bucket.dst.arn}/*"]
  }
}

resource "aws_iam_role" "replication" {
  provider           = aws.src
  name_prefix        = "tfadv-repl-"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

resource "aws_iam_role_policy" "replication" {
  provider = aws.src
  role     = aws_iam_role.replication.id
  policy   = data.aws_iam_policy_document.replication.json
}

resource "aws_s3_bucket_replication_configuration" "this" {
  provider = aws.src
  role     = aws_iam_role.replication.arn
  bucket   = aws_s3_bucket.src.id

  rule {
    id     = "all"
    status = "Enabled"

    filter {}

    delete_marker_replication {
      status = "Disabled"
    }

    destination {
      bucket        = aws_s3_bucket.dst.arn
      storage_class = "STANDARD"
    }
  }

  depends_on = [aws_s3_bucket_versioning.src, aws_s3_bucket_versioning.dst]
}

output "buckets" {
  value = {
    src = aws_s3_bucket.src.id
    dst = aws_s3_bucket.dst.id
  }
}
