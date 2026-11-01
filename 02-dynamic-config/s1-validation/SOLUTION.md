# 02-S1 해설

정답 코드는 `solution/`에 있습니다(`main.tf`, `tests/web.tftest.hcl`).

| 수단 | 실패 시 | 참조 범위(1.6) | 용도 |
|---|---|---|---|
| `variable.validation` | plan 오류 | **해당 변수만** | 단일 입력 형식 |
| `precondition` / `postcondition` | plan/apply 오류 | 다른 객체 참조 가능, postcondition은 `self` | 변수 간 규칙, 가정·보장 |
| `check` 블록 | **경고**(실행 계속) | 모든 객체, 범위 한정 data source 가능 | 지속 점검 |
| `terraform test` | 테스트 실패 | `run` 블록의 `assert`, `expect_failures` | 회귀 테스트 |

- 4: 1.6의 validation은 다른 변수를 참조할 수 없습니다(1.9부터 가능). 그래서 리소스 `lifecycle.precondition`으로 구현합니다. 테스트에서는 `expect_failures = [aws_instance.web]`로 기대 실패를 선언합니다.
- 5: `al2023-ami-2023.*` 필터는 arm64 AMI와도 일치합니다. `most_recent`가 arm64를 고르면 postcondition이 실패하므로, `architecture` 필터를 추가하는 것이 근본 해결책입니다.
- 3: `cidrhost`는 IPv6 CIDR도 받아들입니다. `cidrnetmask`는 IPv4 전용이라 IPv4 검증에 맞습니다.
- 6: check 실패는 경고일 뿐 apply를 막지 않습니다. 값이 unknown(plan 시점)이면 평가를 건너뜁니다.
- 1.6의 test에는 mock provider가 없어서(1.7+) `command = plan`이어도 AWS 자격 증명이 필요합니다(data source 조회).
