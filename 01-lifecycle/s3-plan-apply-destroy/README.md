# 01-S3. init · plan · apply · destroy 옵션 운용

- 목표: **1a** init · **1b** plan · **1c** apply · **1d** destroy
- 형태: Lab · 권장 30분 · 비용: 거의 없음 (S3)

## 상황
리포트 버킷 구성을 단계적으로 배포하고 부분 정리해야 합니다. 각 단계는 **지정한 옵션으로만** 수행하세요.
`answers.txt`에 단계마다 실행한 명령을 한 줄씩 적으세요.

## 과제
1. backend는 초기화하지 않고 provider만 설치한 다음 `terraform validate`를 실행하세요. CI의 lint 단계라고 가정합니다.
2. 이번에는 정상적으로 `terraform init`을 실행하세요. 이어서 lock 파일에 기록된 버전을 무시하고 제약 범위 안의 최신 provider를 받는 init 명령을 실행하세요.
3. **버킷만** 먼저 만드세요. object는 만들면 안 됩니다. state에 무엇이 들어갔는지, 그 이유도 적으세요.
4. 나머지 변경을 `tfplan` 파일로 저장하세요. `terraform show -json tfplan`으로 생성 예정 리소스 수를 jq로 세고, 확인 프롬프트 없이 **저장된 plan 그대로** 적용하세요.
5. `-var`로 `reports`를 `["weekly","monthly"]`로 바꿔 plan만 실행하세요. 결과를 예측해 먼저 적은 뒤 실제 결과와 비교하세요. (힌트: count 인덱스)
6. `daily` 리포트 object를 **내용 변경 없이 강제로 다시 만드세요**.
7. `weekly` object만 파괴하세요. 이어서 전체 파괴 계획을 `destroy.tfplan`으로 저장하고, 그 파일로 파괴하세요.

## 채점 기준
```bash
# 2단계 직후
grep -A1 'hashicorp/aws' .terraform.lock.hcl | grep version   # 제약 범위 안 최신 5.x
# 3단계 직후
terraform state list   # random_integer.suffix, aws_s3_bucket.logs 두 줄만
# 4단계 직후
terraform state list | grep -c report   # 3
# 6단계: apply 출력이 "Apply complete! Resources: 1 added, 0 changed, 1 destroyed."
# 7단계 직후
terraform state list | wc -l            # 0
aws s3api list-buckets --query "Buckets[?starts_with(Name,'tfadv-logs-')].Name" --output text   # 빈 출력
```
`answers.txt`는 `SOLUTION.md`의 명령과 대조하세요.

## 참고 문서
- https://developer.hashicorp.com/terraform/cli/commands/init
- https://developer.hashicorp.com/terraform/cli/commands/plan
- https://developer.hashicorp.com/terraform/cli/commands/apply
- https://developer.hashicorp.com/terraform/cli/commands/destroy
