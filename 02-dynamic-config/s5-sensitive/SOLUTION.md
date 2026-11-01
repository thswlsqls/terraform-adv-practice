# 02-S5 해설

정답 코드는 `solution/main.tf`에 있습니다.

1. 원인 두 가지
   - `output "api_key"`: `random_password.result`는 sensitive인데 출력에 `sensitive = true`가 없어서 "Output refers to sensitive values" 오류가 납니다.
   - `for_each = var.service_tokens`: sensitive 값은 for_each 인자로 쓸 수 없습니다(인스턴스 키가 화면에 노출되기 때문). 키 집합만 `nonsensitive(toset(keys(...)))`로 풀고 값은 `var.service_tokens[each.key]`로 참조합니다. `nonsensitive()`는 **정말 비밀이 아닌 값에만** 쓰세요.
2. `sensitive = true` + `export TF_VAR_db_password=...`. `-var` 인자는 셸 history와 CI 로그에 남습니다.
3. `API_KEY=$(terraform output -raw api_key)` (`-raw`와 `-json`은 sensitive 출력도 그대로 보여 줍니다)
4. `sensitive`는 **출력 마스킹**일 뿐 state와 plan 파일에는 평문으로 들어갑니다. 완화 조치는 다음과 같습니다.
   - 암호화된 원격 backend(S3 SSE-KMS + `encrypt = true`)와 버킷 접근 권한 최소화. HCP Terraform은 state를 암호화해 저장합니다.
   - state와 plan 파일을 VCS에 커밋하지 않기(`.gitignore`), CI 아티팩트로 남기는 plan 파일 접근 통제
   - 비밀을 Terraform에 넣지 않는 설계: 앱이 실행 시점에 Vault나 Secrets Manager에서 직접 조회하고, Terraform은 경로와 권한만 관리
5. Vault 예시

   ```bash
   vault server -dev -dev-root-token-id=root &
   export VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=root
   vault kv put secret/app db_password='S3cr3t!'
   ```

   ```hcl
   # required_providers에 vault = { source = "hashicorp/vault" } 추가
   provider "vault" {}   # VAULT_ADDR / VAULT_TOKEN 환경 변수 사용

   data "vault_kv_secret_v2" "app" {
     mount = "secret"
     name  = "app"
   }

   # content = "DB_PASSWORD=${data.vault_kv_secret_v2.app.data["db_password"]}\n..."
   ```

   실습이 끝나면 `kill %1`(또는 `pkill vault`)로 dev 서버를 종료하세요. dev 서버는 메모리에만 저장하므로 종료하면 데이터도 사라집니다.

   data source로 읽은 값도 state에 저장됩니다. state에 남지 않는 ephemeral 리소스(1.10+)와 write-only 인자(1.11+)는 시험 버전 1.6에서는 쓸 수 없습니다.
