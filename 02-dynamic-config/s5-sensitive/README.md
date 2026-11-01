# 02-S5. 민감 정보 다루기와 Vault 연동

- 목표: **2f** 민감 데이터 관리 모범 사례 (Vault 포함)
- 형태: Lab + 서술 · 권장 30분 · 비용: 없음 (S3) · Vault 단계는 `vault` CLI 필요(선택)

## 상황
앱 설정을 S3에 배포하는 코드가 있습니다. 현재 상태로는 plan조차 실패하고, 비밀번호가 콘솔 출력에 그대로 드러납니다.

## 과제
1. `terraform plan -var db_password=dummy`가 실패하는 **두 가지** 원인을 찾아 고치세요. 비밀 값은 계속 비밀로 유지해야 합니다.
2. `db_password`가 plan 출력과 CLI 기록에 남지 않게 하세요. 입력은 `.tfvars` 파일을 커밋하는 대신 환경 변수로 넣으세요.
3. apply한 뒤 `api_key` 값을 **셸 변수에 담는** 명령을 쓰세요.
4. state 파일에 비밀이 평문으로 저장되는지 직접 확인하세요. 이를 완화하는 운영 조치 3가지를 `answers.txt`에 적으세요.
5. (선택: Vault) 로컬 Vault dev 서버의 `secret/app`에 `db_password`를 넣고, 변수 대신 Vault에서 읽어 쓰세요. 이렇게 해도 state 문제가 남는 이유를 적으세요.

## 채점 기준
```bash
export TF_VAR_db_password='S3cr3t!'
echo 'var.db_password' | terraform console              # (sensitive value)
terraform apply -auto-approve
API_KEY=$(terraform output -raw api_key); echo ${#API_KEY}   # 32
terraform state pull | grep -c 'S3cr3t'                  # 1 이상 (state는 평문)
aws s3 ls "s3://$(terraform state show aws_s3_bucket.config | awk -F'"' '/^ +bucket +=/{print $2}')/tokens/"   # billing, shipping
```

## 정리
`terraform destroy`

## 참고 문서
- https://developer.hashicorp.com/terraform/language/state/sensitive-data
- https://developer.hashicorp.com/terraform/language/values/outputs#sensitive-suppressing-values-in-cli-output
- https://registry.terraform.io/providers/hashicorp/vault/latest/docs/data-sources/kv_secret_v2
