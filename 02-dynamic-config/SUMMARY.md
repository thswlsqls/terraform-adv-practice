# 02. 동적 구성 핵심 정리

목표 2(2a 검증 · 2b data source · 2c 함수 · 2d 메타 인자 · 2e 변수·출력·복합 타입 · 2f 민감 정보)에서 S1~S5를 풀며 익혀야 할 내용입니다. 환경은 Terraform 1.6 기준입니다.

## 1. 검증 수단 4가지 (S1)

| 수단 | 실패 시 | 참조 범위(1.6) | 언제 쓰나 |
|---|---|---|---|
| `variable { validation }` | plan 오류 | **자기 변수만** | 단일 입력 형식(허용 목록, CIDR 형식) |
| `lifecycle { precondition }` | plan/apply 오류 | 다른 변수·리소스 | 변수 간 규칙(`prod`면 `t3.small`), 사용 전 가정 |
| `lifecycle { postcondition }` | plan/apply 오류 | `self` | 결과 보장(조회된 AMI가 x86_64인지) |
| `check { assert }` | **경고만** | 모든 객체, 범위 한정 data source | 지속 점검(인스턴스 running 여부) |
| `terraform test` | 테스트 실패 | `run`의 `assert`, `expect_failures` | 회귀 테스트 |

- 변수 간 규칙을 validation에 쓰는 것은 1.9부터 가능합니다. **1.6에서는 precondition으로** 구현합니다.
- IPv4 CIDR 검증에는 `can(cidrnetmask(x))`를 씁니다. `cidrhost`는 IPv6도 통과시킵니다.
- postcondition이 실패하면 조건만 고치지 말고 **원인**(data source 필터 누락)을 고칩니다.
- `.tftest.hcl` 규칙: 기본값은 `command = apply`이고, 기대 실패는 `expect_failures = [var.x]` 또는 `[aws_instance.web]`로 적습니다. mock provider는 1.7+라서 1.6에서는 plan만 해도 자격 증명이 필요합니다.

## 2. data source (S2)

| data source | 주의점 |
|---|---|
| `aws_ami` | `owners` 필수(누락 시 타인 AMI 위험), 여러 개면 `most_recent = true`, 0개면 오류 |
| `aws_subnet` | 결과가 **정확히 1개**여야 함. 여러 개는 `aws_subnets` |
| `aws_availability_zones` | `state = "available"` → `names[0]` |
| `aws_caller_identity` | `account_id`, `arn` (assumed-role이면 세션 ARN) |
| `aws_iam_session_context` | `issuer_arn`: assumed-role 세션 ARN을 **원래 역할 ARN**으로 변환 |
| `aws_iam_policy_document` | 문법 검증·정규화로 diff 감소, `source_policy_documents`로 병합. JSON heredoc 대체 |

- 최소 권한: `s3:ListBucket`은 버킷 ARN에, `s3:GetObject`는 `버킷 ARN/*`에 줍니다.
- IAM 연결 체인: `aws_iam_role` → `aws_iam_role_policy_attachment` → `aws_iam_instance_profile` → `aws_instance.iam_instance_profile`
- **`depends_on`은 숨은 의존성에만** 씁니다. 인스턴스는 profile→role만 참조하므로 정책 attachment와의 순서가 보장되지 않습니다. 남용하면 `(known after apply)`가 늘어납니다.
- data source 인자가 unknown이면 읽기가 apply 단계로 미뤄집니다.

## 3. 함수·표현식 (S3)

| 분류 | 함수 / 문법 | 기억할 점 |
|---|---|---|
| 파일 | `file`, `csvdecode`, `templatefile` | `csvdecode` 값은 **전부 문자열** → `tonumber`, `== "true"` |
| 맵·컬렉션 | `merge`, `lookup(m,k,default)`, `keys`, `one`, `distinct`, `flatten`, `setproduct` | `merge`는 뒤 인자가 이김, `one`은 0개→null·2개 이상→오류 |
| 정렬 | `sort` | 문자열 사전순(코드포인트): `"10" < "9"`, 대문자 < 소문자 |
| 네트워크 | `cidrsubnet(prefix, newbits, num)`, `cidrnetmask` | `/16`+4 = `/20`, num번째 블록 |
| 오류 처리 | `try`, `can`, `coalesce` | `coalesce`는 null과 `""`를 건너뜀 |
| 인덱스 | `element(list, i)` | 범위를 넘으면 순환(i % length) |
| for | `[for k, v in m : ...]`, `{ for x in l : k => v... }` | 맵은 키 사전순 순회, `...`은 그룹 모드 |
| splat | `list[*].attr` | 0개면 빈 리스트 → `one()`과 조합 |

- 복합 타입: `list(object({ ..., description = optional(string, "기본값") }))` (`optional` 기본값은 1.3+)
- `dynamic "egress" { for_each = ...; content { ... } }`: 반복 대상은 **중첩 블록**이고, 반복 변수 이름은 블록 이름(`egress.value`)입니다.
- 인라인 규칙과 별도 규칙 리소스를 **같은 방향에** 섞지 않습니다. 서로 덮어써서 영구 diff가 납니다.

### 변수 우선순위 (낮음 → 높음)
```
default < TF_VAR_* < terraform.tfvars < terraform.tfvars.json < *.auto.tfvars(사전순) < -var / -var-file(나중 것 우선)
```

## 4. 메타 인자 (S4)

| 요구사항 | 해법 |
|---|---|
| 교체 시 새 것을 먼저 생성 | `create_before_destroy = true` + 고정 `name` 대신 `name_prefix`(이름 충돌 방지) |
| 외부에서 바꾸는 값을 되돌리지 않기 | `ignore_changes = [desired_capacity]` |
| destroy 방지 | `prevent_destroy = true` (파괴를 포함한 **plan 자체가 오류**, 블록을 지우면 보호도 사라짐) |
| 조건부 리소스 | `count = var.enable ? 1 : 0` |
| 조건부 리소스의 출력 | `one(aws_instance.x[*].id)` → 없으면 null (`[0]` 인덱싱은 count 0일 때 오류) |
| 변수 변경 시 교체 | `terraform_data { input = var.release }` + `replace_triggered_by = [terraform_data.release]` (변수 직접 참조 불가) |
| LT 새 버전 시 롤링 교체 | ASG 인자 `instance_refresh { strategy = "Rolling" }` (lifecycle 아님) |

- CBD는 **의존 대상**에도 자동 전파됩니다.
- 옛 SG 삭제를 막는 것은 LT가 아니라 그 SG를 쓰는 **ENI(인스턴스)** 입니다(`DependencyViolation`).
- 값이 null인 루트 출력은 state에 저장되지 않습니다. `terraform output x`를 실행하면 not found가 나옵니다.

## 5. 민감 정보 (S5)

- `sensitive = true`는 **화면 마스킹**일 뿐입니다. state와 plan 파일에는 평문으로 저장됩니다.
- 자주 나는 오류:
  - sensitive 값을 출력하면서 `sensitive = true`가 없으면 → `Output refers to sensitive values`
  - sensitive 값을 `for_each`에 넣으면 → 오류. 키만 `nonsensitive(toset(keys(m)))`로 풀고, `nonsensitive`는 정말 비밀이 아닌 값에만 씁니다.
- 입력: `export TF_VAR_x=...`. `-var`는 history와 로그에 남고, `.tfvars`는 커밋 위험이 있습니다.
- 꺼내기: `terraform output -raw x` 또는 `-json`(sensitive도 평문으로 보여 줌)
- 완화: 암호화된 원격 backend + 접근 통제, state·plan 파일 비커밋, 앱이 런타임에 Vault/Secrets Manager에서 직접 조회
- Vault data source(`vault_kv_secret_v2`)로 읽어도 **state에 남습니다**. ephemeral(1.10+)과 write-only(1.11+)는 1.6에서 쓸 수 없습니다.

## 6. 1.6 버전 함정

| 기능 | 도입 버전 | 1.6 대안 |
|---|---|---|
| validation에서 다른 변수 참조 | 1.9 | precondition |
| `terraform test` | 1.6 | 사용 가능 |
| test mock provider / `override_*` | 1.7 | 자격 증명으로 실제 plan |
| `check` 블록 | 1.5 | 사용 가능 |
| `terraform_data` | 1.4 | 사용 가능 (`null_resource` 대체) |
| `optional(type, default)` | 1.3 | 사용 가능 |
| ephemeral 리소스 / write-only 인자 | 1.10 / 1.11 | 설계로 비밀을 Terraform 밖에 두기 |
