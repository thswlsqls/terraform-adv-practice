# 03-S2 해설

```hcl
# app/backend.tf
terraform {
  backend "s3" {}
}
```

```hcl
# app/backend.hcl
bucket         = "tfadv-state-<account_id>"
key            = "app/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "tfadv-state-lock"
encrypt        = true
```

```bash
terraform init -backend-config=backend.hcl -migrate-state   # "Do you want to copy existing state?" → yes
rm terraform.tfstate terraform.tfstate.backup                # 원격 확인 후
# 3. B 터미널
terraform plan -var bucket=$B                   # Error: Error acquiring the state lock (Lock Info: ID, Who, Operation)
terraform plan -var bucket=$B -lock-timeout=60s
# 4.
terraform force-unlock <LOCK_ID>                # 같은 backend 설정의 디렉터리에서 실행
# 6.
terraform init -backend-config=backend.hcl -migrate-state   # key 변경 후 state 복사
terraform init -backend-config=backend.hcl -reconfigure     # 기존 state 무시, 새 backend로 시작
```

```bash
#!/usr/bin/env bash
# app/ci.sh  (작성 후 chmod +x ci.sh)
set -uo pipefail
export TF_IN_AUTOMATION=1
terraform init -input=false -backend-config=backend.hcl || exit 1
terraform plan -input=false -lock-timeout=120s -out=tfplan -detailed-exitcode
case $? in
  0) echo "no changes; skip apply"; exit 0 ;;
  2) terraform apply -input=false tfplan ;;
  *) echo "plan failed"; exit 1 ;;
esac
```

- `set -e`를 쓰면 종료 코드 2(변경 있음)에서도 스크립트가 끝나 버립니다. 그래서 `-e` 없이 `case`로 분기합니다.
- `TF_IN_AUTOMATION`은 "다음에 terraform apply를 실행하세요" 같은 안내 문구를 줄입니다. 입력 프롬프트는 `-input=false`로 막습니다. 변수는 `TF_VAR_*` 환경 변수로 넣습니다.
- `-lock=false`는 잠금을 건너뛰는 위험한 옵션입니다. `force-unlock`은 **다른 프로세스가 실제로 실행 중이 아닐 때만** 쓰세요.
- backend 블록에서는 변수를 쓸 수 없습니다. 그래서 환경별 값은 `-backend-config`로 주입합니다(파일 또는 `key=value`).
- 버킷 versioning을 켜 두면 state가 손상됐을 때 이전 버전으로 복구할 수 있습니다.
