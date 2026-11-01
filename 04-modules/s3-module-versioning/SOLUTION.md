# 04-S3 해설

```hcl
# module-repo/main.tf (v1.1.0)
variable "versioning" {
  type        = bool
  default     = true
  description = "버킷 versioning 활성화"
}

resource "aws_s3_bucket" "this" {
  bucket_prefix = "${var.name}-"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = var.versioning ? "Enabled" : "Suspended"
  }
}

moved {
  from = aws_s3_bucket.bucket
  to   = aws_s3_bucket.this
}

output "bucket_id" {
  value = aws_s3_bucket.this.id
}
```

```bash
cd module-repo && git -c user.name=lab -c user.email=lab@example.com commit -am "v1.1.0: rename to this, add versioning" && git tag v1.1.0
cd ../consumer && sed -i '' 's/ref=v1.0.0/ref=v1.1.0/' main.tf && terraform init && terraform plan   # macOS sed
```

- 모듈 **안의** `moved` 블록은 모듈 상대 주소(`aws_s3_bucket.bucket`)로 씁니다. 소비자는 아무것도 바꾸지 않아도 `module.store.aws_s3_bucket.bucket has moved to module.store.aws_s3_bucket.this`가 적용됩니다.
- MINOR인 이유: 새 입력에 기본값이 있고, 주소 변경이 `moved`로 투명하게 처리되며, 출력 계약도 그대로입니다. 소비자 코드를 바꿀 필요가 없습니다.
- v2.0.0: 필수 입력 이름이 바뀌면 소비자가 `name = ...`을 `name_prefix = ...`로 고쳐야 하므로 MAJOR입니다.
- 4: v2.0.0에도 `moved { from = aws_s3_bucket.bucket ... }`이 **남아 있어야** 합니다. 모듈의 moved 블록은 오래 유지하고, 지우는 일 자체를 MAJOR 변경으로 다루세요.
- `ref`를 바꾸면 source 문자열이 달라지므로 `terraform init`이 새 revision을 받습니다. 레지스트리 모듈이라면 `version`을 바꾸고 `terraform init -upgrade`를 실행합니다.
