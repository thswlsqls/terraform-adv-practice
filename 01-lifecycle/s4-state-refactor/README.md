# 01-S4. 주소 리팩터링과 state 조작

- 목표: **1e** state 관리 (moved, state 명령, 관리 중단)
- 형태: Lab · 권장 25분 · 비용: 거의 없음

## 상황
`aws_s3_bucket.b`는 이름이 모호하고 count 기반이라, 목록 순서가 바뀌면 버킷이 교체될 위험이 있습니다.
임시 버킷 `tmp`는 데이터팀에 넘기기로 해서, 버킷은 남기고 Terraform 관리만 끝내야 합니다.

## 준비
```bash
terraform init && terraform apply -auto-approve
terraform state list > before.txt
```

## 과제
1. `aws_s3_bucket.b`를 `aws_s3_bucket.data`로 이름을 바꾸고 `for_each = toset(var.buckets)`로 전환하세요. **어떤 버킷도 교체·삭제되면 안 됩니다.** CLI 대신 설정으로 처리하세요.
2. `tmp` 버킷의 관리를 끝내되, 실제 버킷은 AWS에 남겨 두세요. (주의: 이 시험 환경은 Terraform 1.6입니다.)
3. `aws_s3_bucket.data["raw"]`의 ARN을 state에서 조회해 `answers.txt`에 적으세요. 이어서 `terraform show -json`과 jq로 관리 중인 리소스 수를 세세요.
4. 1을 `terraform state mv`로 처리했다면 무엇이 달라지는지 2줄로 설명하세요.

## 채점 기준
```bash
terraform plan -detailed-exitcode; echo $?     # 0
terraform state list                            # aws_s3_bucket.data["curated"], aws_s3_bucket.data["raw"] 두 줄
aws s3api list-buckets --query "Buckets[?starts_with(Name,'tfadv-tmp-')].Name" --output text   # 남아 있음
```
1의 plan 출력에는 `has moved to`가 2건, `0 to add, 0 to change, 0 to destroy`가 나와야 합니다.

## 정리
`terraform destroy`, 이어서 `aws s3 rb s3://<tfadv-tmp-...> --force`

## 참고 문서
- https://developer.hashicorp.com/terraform/language/moved
- https://developer.hashicorp.com/terraform/cli/commands/state
