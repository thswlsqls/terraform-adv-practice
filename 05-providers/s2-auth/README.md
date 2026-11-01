# 05-S2. provider 인증: 하드코딩 제거와 AssumeRole

- 목표: **5c** provider 인증 관리 (+ 5d 권한 오류 해석)
- 형태: Lab · 권장 30분 · 비용: 없음 (IAM, S3)

## 상황
`deploy/versions.tf`의 provider 블록에 액세스 키가 하드코딩되어 있습니다(예시 키라 동작하지 않음).
보안팀 요구 사항은 다음과 같습니다. "코드에는 자격 증명을 두지 않는다. 배포는 권한이 제한된 `tfadv-deployer` 역할로만 한다."

## 준비
```bash
cd role && terraform init && terraform apply -auto-approve && cd ..
```

## 과제
1. `deploy/`의 하드코딩 키를 지우세요. 자격 증명은 **코드 밖**(환경 변수, 공유 credentials/config 파일 프로필 등)에서 주입합니다. AWS provider가 자격 증명을 찾는 순서를 `answers.txt`에 적으세요.
2. provider가 `role/` 출력의 역할을 **assume**해서 리소스를 만들게 하세요. 역할 ARN은 변수로 받고, 세션 이름은 `tfadv-deploy`로 합니다.
3. 출력 2개를 추가하세요.
   - `caller_arn`: 실제 API 호출 주체 ARN (`assumed-role/tfadv-deployer/tfadv-deploy`가 보여야 함)
   - `issuer_arn`: 그 세션을 발급한 역할 ARN
4. `-var try_forbidden=true`로 apply를 실행하고, 권한 오류 메시지에서 **실패한 API 동작과 주체**를 찾아 `answers.txt`에 적으세요.
5. 같은 구성을 CI에서 **장기 키 없이** 실행하는 방법 두 가지를 적으세요.

## 채점 기준
```bash
grep -nE 'access_key|secret_key|AKIA' deploy/*.tf      # 출력 없음
cd deploy && terraform apply -auto-approve -var role_arn=$(terraform -chdir=../role output -raw role_arn)
terraform output caller_arn    # arn:aws:sts::<acct>:assumed-role/tfadv-deployer/tfadv-deploy
terraform output issuer_arn    # arn:aws:iam::<acct>:role/tfadv-deployer
```

## 정리
`deploy`: `terraform destroy -var role_arn=...` → `role`: `terraform destroy`

## 참고 문서
- https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration
- https://registry.terraform.io/providers/hashicorp/aws/latest/docs#assume_role-configuration-block
