# 02-S1. 입력 검증 · 사용자 정의 조건 · check · terraform test

- 목표: **2a** 언어 기능으로 설정 검증 (Tests, Checks, 입력 변수, 타입 제약, custom conditions)
- 형태: Lab · 권장 30분 · 비용: t3.micro 1대 (5단계에서만)

## 상황
플랫폼팀 규칙을 코드로 강제해야 합니다. 잘못된 입력은 **plan 단계에서** 명확한 메시지와 함께 실패해야 합니다.

## 과제
1. `env`는 `dev`, `stg`, `prod`만 허용합니다.
2. `instance_type`은 `t3.micro`, `t3.small`만 허용합니다.
3. `allowed_cidr`는 유효한 **IPv4** CIDR여야 합니다(`10.0.0.0/33`, `::/0`은 거부).
4. **`env = "prod"`이면 `instance_type`은 `t3.small`이어야 합니다.** (주의: Terraform 1.6)
5. 조회된 AMI는 `x86_64`여야 합니다. 이 규칙이 실패하면 data source 쪽의 근본 원인도 고치세요.
6. 인스턴스가 `running`이 아니면 apply를 **막지 않고 경고만** 내세요.
7. `tests/web.tftest.hcl`을 작성해 1~4를 검증하고 `terraform test`가 통과하게 하세요. 테스트는 `command = plan`만 사용해 인프라를 만들지 않습니다.

## 채점 기준
```bash
terraform validate
terraform test                                              # 모든 run pass
terraform plan -var env=dev -var instance_type=m5.large     # instance_type 메시지와 함께 실패
terraform plan -var env=prod                                # precondition 메시지와 함께 실패
terraform plan -var env=dev -var allowed_cidr=::/0          # allowed_cidr 메시지와 함께 실패
grep -c '^run ' tests/web.tftest.hcl                       # 4 이상 (규칙 1~4)
terraform apply -var env=dev -auto-approve                  # 성공
```

## 정리
`terraform destroy -var env=dev`

## 참고 문서
- https://developer.hashicorp.com/terraform/language/expressions/custom-conditions
- https://developer.hashicorp.com/terraform/language/checks
- https://developer.hashicorp.com/terraform/language/tests
