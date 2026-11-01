# 01-S4 해설

```hcl
resource "aws_s3_bucket" "data" {
  for_each      = toset(var.buckets)
  bucket_prefix = "tfadv-${each.key}-"
  force_destroy = true
}

moved {
  from = aws_s3_bucket.b[0]
  to   = aws_s3_bucket.data["raw"]
}

moved {
  from = aws_s3_bucket.b[1]
  to   = aws_s3_bucket.data["curated"]
}
```

```bash
# 2. removed 블록은 1.7+ → 1.6에서는 블록을 지운 뒤 state에서만 제거
terraform state rm aws_s3_bucket.tmp
# 3.
terraform state show 'aws_s3_bucket.data["raw"]' | grep -E '^\s+arn'
terraform show -json | jq '[.values.root_module.resources[] | select(.mode=="managed")] | length'   # 2
```

- 블록만 지우고 `state rm`을 하지 않으면 다음 apply에서 버킷이 **파괴**됩니다(`force_destroy = true`라서 내용까지 함께).
- 4: `state mv`는 state를 즉시 바꿉니다. 코드 리뷰가 불가능하고, 같은 state를 쓰는 다른 작업자나 다른 모듈 사용자에게 이력이 전달되지 않습니다. `moved`는 plan에서 미리 볼 수 있고 코드로 남아서 모든 사용처에 같은 리팩터링이 적용됩니다.
- `moved` 블록은 일정 기간 남겨 두세요. 아직 예전 주소를 쓰는 state(다른 workspace 등)가 있을 수 있습니다.
- 관련 명령(객관식 대비): `state list -id=<id>`, `state pull`/`state push`(직렬 번호 검사, `-force`는 위험), `terraform show <planfile>`.
