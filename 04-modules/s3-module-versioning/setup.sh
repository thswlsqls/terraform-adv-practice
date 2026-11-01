#!/usr/bin/env bash
# 모듈 저장소(module-repo, 로컬 git)에 v1.0.0을 만들고 consumer가 그 태그를 참조하게 한다
set -euo pipefail
ROOT=$(cd "$(dirname "$0")" && pwd)
REPO="$ROOT/module-repo"

rm -rf "$REPO" && mkdir -p "$REPO" && cd "$REPO"
git init -q
cat > main.tf <<'TF'
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

variable "name" {
  type        = string
  description = "버킷 이름 접두사"
}

resource "aws_s3_bucket" "bucket" {
  bucket_prefix = "${var.name}-"
  force_destroy = true
}

output "bucket_id" {
  value = aws_s3_bucket.bucket.id
}
TF
git add . && git -c user.name=lab -c user.email=lab@example.com commit -qm "v1.0.0" && git tag v1.0.0

cat > "$ROOT/consumer/main.tf" <<TF
module "store" {
  source = "git::file://$REPO?ref=v1.0.0"
  name   = "tfadv-store"
}

output "bucket_id" {
  value = module.store.bucket_id
}
TF
echo "module repo: $REPO (tags: $(git tag | tr '\n' ' '))"
