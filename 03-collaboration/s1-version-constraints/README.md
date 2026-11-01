# 03-S1. Terraform·provider·module 버전 제약과 lock 파일

- 목표: **3a** 버전 제약으로 바이너리·provider·모듈 관리 (+ 5b 업그레이드)
- 형태: Lab · 권장 25분 · 비용: 없음 (AWS 리소스 없음)

## 상황
다른 팀에서 넘겨받은 저장소가 `terraform init`부터 실패합니다. 커밋된 `.terraform.lock.hcl`은 오래전 것입니다.
팀 표준은 다음과 같습니다.

- Terraform: **1.6 패치 버전만** 허용(1.7 불가)
- AWS provider: **5.40 이상, 6.0 미만**
- random provider: 하위 모듈 요구 사항을 만족하는 **3.x**
- 팀원은 macOS(arm64)를 쓰고 CI는 Linux(amd64)를 씁니다

## 과제
1. 먼저 `terraform version`으로 **이 디렉터리에서 실제로 실행되는 바이너리**를 확인하세요(4번 참고). 그다음 `terraform init`이 실패하는 원인을 **순서대로** 고치세요. 오류 메시지마다 원인과 조치를 `answers.txt`에 적으세요.
2. 제약을 고쳤는데도 lock 파일 때문에 init이 실패합니다. lock 파일을 **손으로 지우거나 고치지 않고** 해결하세요.
3. CI(Linux)에서 checksum 오류가 나지 않도록, init을 다시 실행하지 않고 lock 파일에 두 플랫폼의 해시를 기록하세요.
4. 이 디렉터리에서 `tfenv`가 1.6.6을 자동으로 고르게 만드세요. 무엇이 1.7.5를 고르게 만들고 있는지 먼저 찾으세요.
5. 아래 질문에 답하세요.
   - lock 파일은 VCS에 커밋해야 하나요? 모듈 버전도 lock 파일에 기록되나요?
   - 레지스트리 모듈이 `version = "1.4.0"`으로 고정되어 있을 때, 새 버전으로 올리는 올바른 절차는 무엇인가요?
   - `~> 5.40`과 `~> 5.40.0`은 각각 어떤 범위인가요?

## 채점 기준
```bash
terraform init -input=false            # 성공
terraform version                      # provider aws v5.x (>= 5.40), random v3.x (>= 3.5)
grep -A2 'hashicorp/aws' .terraform.lock.hcl | grep -E 'version|constraints'   # 5.x, "~> 5.40"
grep -c 'h1:' .terraform.lock.hcl      # 4 이상 (provider 2개 × 플랫폼 2개)
cat .terraform-version                 # 1.6.6
terraform apply -auto-approve && terraform output label   # "app-xxxxxxxx"
```

## 참고 문서
- https://developer.hashicorp.com/terraform/language/settings#specifying-a-required-terraform-version
- https://developer.hashicorp.com/terraform/language/expressions/version-constraints
- https://developer.hashicorp.com/terraform/language/files/dependency-lock
- https://developer.hashicorp.com/terraform/cli/commands/providers/lock
