# 03-S2. S3 원격 state 이전, 잠금, 자동화 실행

- 목표: **3b** 원격 state 구성 · **3c** 자동화 환경의 워크플로 (+ 1a init 옵션)
- 형태: Lab · 권장 40분 · 비용: 거의 없음 (S3, DynamoDB 온디맨드)

## 상황
`app/`은 로컬 state로 운영되어 왔습니다. 팀 공유와 CI 실행을 위해 S3 backend로 옮기고 동시 실행을 막아야 합니다.
(시험 버전 1.6의 S3 backend는 DynamoDB로 잠금을 처리합니다. `use_lockfile`은 1.10+ 기능입니다.)

## 준비
```bash
cd bootstrap && terraform init && terraform apply -auto-approve && cd ..
cd app && terraform init && terraform apply -auto-approve -var bucket=$(terraform -chdir=../bootstrap output -raw bucket)
```

## 과제
1. `app/`에 S3 backend를 **부분 구성(partial configuration)**으로 추가하세요. 코드에는 `backend "s3" {}`만 두고, 값은 `app/backend.hcl`에 넣습니다.
   - key `app/terraform.tfstate`, 암호화, DynamoDB 잠금
2. 기존 로컬 state를 **리소스 재생성 없이** S3로 옮기세요. 이전이 끝나면 로컬 `terraform.tfstate`를 정리하세요.
3. 잠금 확인: 터미널 A에서 `terraform apply`를 실행하고 승인 프롬프트에서 멈추세요. 그동안 터미널 B에서 `terraform plan`을 실행하고 오류 메시지를 기록하세요. 이어서 B가 **60초까지 기다리도록** 다시 실행하세요.
4. 비정상 종료로 남은 잠금 해제: A를 `kill -9`로 종료하면 잠금이 남습니다. Lock ID를 확인해 해제하세요.
5. `app/ci.sh`를 작성하세요. 요구 사항은 다음과 같습니다.
   - 대화형 프롬프트 없음, 자동화 모드 출력
   - backend 설정은 `backend.hcl`로 주입
   - plan 결과를 파일로 저장하고 **종료 코드로 변경 유무를 판별**: 변경 없으면 apply를 건너뛰고, 오류면 실패 처리
   - 저장된 plan만 apply
6. backend key를 `app/v2/terraform.tfstate`로 바꿔야 합니다. state를 **복사해 가는** init 옵션과 **복사 없이 새로 시작하는** init 옵션을 각각 적으세요.

## 채점 기준
```bash
B=$(terraform -chdir=../bootstrap output -raw bucket)
aws s3api head-object --bucket "$B" --key app/terraform.tfstate >/dev/null && echo remote-ok
test ! -s terraform.tfstate && echo local-clean
terraform plan -detailed-exitcode -var bucket=$B; echo $?   # 0 (이전 후 변경 없음)
aws dynamodb scan --region us-east-1 --table-name tfadv-state-lock \
  --query 'length(Items[?!ends_with(LockID.S, `-md5`)])'    # 0 (남은 잠금 없음, -md5는 digest 항목)
TF_VAR_bucket=$B ./ci.sh; echo $?                          # 0, "no changes; skip apply"
aws s3 rm "s3://$B/$(terraform state show aws_s3_object.marker | awk -F'"' '/^    key +=/{print $2}')"   # 드리프트 유발
TF_VAR_bucket=$B ./ci.sh; echo $?                          # 0, apply 실행 (plan 종료 코드 2 경로)
TF_VAR_bucket=$B ./ci.sh; echo $?                          # 0, 다시 skip
TF_VAR_bucket=$B TF_CLI_ARGS_plan="-var=undeclared=1" ./ci.sh; echo $?   # 1 (plan 오류 경로, apply 안 함)
```

## 정리
`app`: `terraform destroy`
**03-S3으로 이어서 진행한다면 `bootstrap`은 남겨 두세요.** 03-S3 정리 단계에서 함께 지웁니다.

## 참고 문서
- https://developer.hashicorp.com/terraform/language/settings/backends/s3
- https://developer.hashicorp.com/terraform/language/settings/backends/configuration#partial-configuration
- https://developer.hashicorp.com/terraform/language/state/locking
- https://developer.hashicorp.com/terraform/tutorials/automation/automate-terraform
