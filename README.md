# HCTOA-002-AWS 시나리오 실습 계획

HashiCorp Certified: **Terraform Authoring & Operations Advanced with AWS**(HCTOA-002-AWS)를 대비하는 Lab형 시나리오 문제 모음입니다.

## 1. 공식 출처 분석 (2026-10-30 확인)

| 출처 | 내용 | 이 계획에서의 역할 |
|---|---|---|
| [certifications/terraform-advanced](https://developer.hashicorp.com/certifications/terraform-advanced) | **Lab 시나리오 + 객관식**, 4시간(휴식 15분), **Terraform 1.6**, 목표 6개 영역 27개 | **분류 기준(정본)** |
| [pro-cert/adv-review](https://developer.hashicorp.com/terraform/tutorials/pro-cert/adv-review) | 목표별 문서 목록, **AWS 리소스 목록**, 영역 6은 **객관식 전용** | 시나리오 리소스 선택 기준 |
| [pro-cert/adv-study](https://developer.hashicorp.com/terraform/tutorials/pro-cert/adv-study), [adv-orientation](https://developer.hashicorp.com/terraform/tutorials/pro-cert/adv-orientation) | 학습 팁(targeting, 주소 리팩터링 등). 채점은 **구성 문법, state, 실제 리소스 설정**으로 함. 시험 중 Terraform·클라우드 문서 열람 가능 | 문제 양식, 채점 방식 |
| [cert-pro-study](https://developer.hashicorp.com/terraform/tutorials/certification-infra-professional/cert-pro-study), [cert-pro-review](https://developer.hashicorp.com/terraform/tutorials/certification-infra-professional/cert-pro-review) (요청에서 지정한 URL) | 현재는 **다른 시험**인 *Terraform Infrastructure Engineer Professional (002)* 의 자료입니다. 객관식 전용, **TF 1.15**, 7개 영역 40개 | [부록 A](#부록-a-지정-url-pro-002-항목-대응표)에 대응표로 연결 |

> 2026년 가을 개편 때 기존 Lab형 "Terraform Professional"은 **Terraform Authoring and Operations Advanced**로 이름이 바뀌었습니다. 같은 이름 계열의 `certification-infra-professional` 경로는 새 객관식 시험을 가리킵니다. 그래서 문제 분류는 HCTOA 목표를 따르고, 지정된 URL의 항목은 커버 여부만 대조했습니다.

## 2. 설계 원칙

1. **시험 형식을 그대로 따릅니다.** 한 시나리오는 상황 1개와 여러 과제로 구성됩니다. Lab 채점 기준은 `validate`/`plan -detailed-exitcode`(구성), `state list/show`(state), `aws` CLI(실제 리소스 설정)의 세 가지입니다.
   - `answers.txt`에 적는 서술·명령 회상 과제는 실제 Lab에는 없습니다. 시험의 **객관식 파트 대비용**이라 Lab 채점에서 제외하고 `SOLUTION.md`로 자가 채점합니다.
2. **버전은 1.6으로 고정합니다**(`.terraform-version` = 1.6.6). 1.7 이후 기능을 쓰지 않는 것도 실력입니다(아래 함정표).
3. **AWS 리소스는 공식 목록 위주로 고릅니다.** 공식 목록(18종 + S3 backend + `terraform_remote_state`)이 등장하는 곳은 다음과 같습니다. 일부는 시작 코드로만 제공됩니다(`random_integer`, LT/ASG 본체).
   - `aws_instance`, `aws_ami`: 01-S1, 02-S1, 02-S2, 04-S1
   - `aws_launch_template`, `aws_autoscaling_group`: 02-S4
   - `aws_security_group`: 01-S1, 02-S3, 04-S1
   - `aws_security_group_rule`: 02-S4
   - `aws_vpc_security_group_ingress_rule`: 02-S3, 04-S1
   - `aws_s3_bucket`, `aws_s3_object`, `random_integer`: 01-S3, 03-S2
   - `aws_subnet`: 02-S2, 04-S1
   - `aws_caller_identity`, `aws_iam_session_context`: 02-S2, 05-S2
   - `aws_iam_policy_document`, `aws_iam_role`, `aws_iam_policy`, `aws_iam_role_policy_attachment`, `aws_iam_instance_profile`: 02-S2 (`aws_iam_policy_document`, `aws_iam_role`는 05-S1, 05-S2에도)
   - S3 backend, `terraform_remote_state`: 03-S2, 03-S3
4. **오버엔지니어링은 하지 않습니다.** 자동 채점기, CI, 공통 모듈 프레임워크는 만들지 않습니다. 시나리오마다 독립 디렉터리 하나로 끝냅니다(시험의 lab도 독립 채점).

## 3. 구조

```
terraform-adv-practice/
├── .terraform-version          # 1.6.6
├── 01-lifecycle/               # 목표 1  import, drift, plan/apply/destroy 옵션, state
├── 02-dynamic-config/          # 목표 2  validation·test, data source, 함수·표현식, 메타 인자, 민감 정보
├── 03-collaboration/           # 목표 3  버전 제약·lock, S3 원격 state·잠금·자동화, remote_state·workspace
├── 04-modules/                 # 목표 4  모듈화+moved, 레지스트리 모듈, 모듈 버저닝
├── 05-providers/               # 목표 5  alias 두 리전, 인증·AssumeRole, 트러블슈팅
├── 06-hcp-terraform/           # 목표 6  객관식 전용 → 문항 22개
└── scripts/leftovers.sh        # 실습 후 남은 리소스 점검
```
시나리오 디렉터리에는 `README.md`(문제), 시작 코드, `SOLUTION.md`(해설)가 있고, 필요하면 `solution/`(정답 코드)과 `setup.sh`가 함께 있습니다.

## 4. 목표 ↔ 시나리오 매핑 (27/27)

| 목표 | 세부 목표 | 주 시나리오 | 보조 |
|---|---|---|---|
| 1 리소스 수명주기 | 1a init 옵션 | 01-S3 | 03-S1, 03-S2 |
| | 1b plan 옵션 | 01-S3 | 01-S2 |
| | 1c apply 옵션 | 01-S3 | 01-S2 |
| | 1d destroy 옵션 | 01-S3 | 02-S4 |
| | 1e state·import·drift | 01-S1, 01-S2, 01-S4 | 04-S1 |
| 2 동적 구성 | 2a 언어 기능으로 검증 | 02-S1 | |
| | 2b data source | 02-S2 | 03-S3 |
| | 2c HCL 함수 | 02-S3 | 02-S2 |
| | 2d 메타 인자 | 02-S4 | 02-S2(`depends_on`), 02-S3, 04-S1, 05-S1 |
| | 2e 변수·출력·복합 타입 | 02-S3 | 02-S2, 04-S1 |
| | 2f 민감 정보·Vault | 02-S5 | |
| 3 협업 워크플로 | 3a 바이너리·provider·모듈 버전 | 03-S1 | 04-S3, 05-S3 |
| | 3b 원격 state | 03-S2 | 03-S3 |
| | 3c 자동화 워크플로 | 03-S2 | |
| | 3d 구성·workspace 간 데이터 공유 | 03-S3(구성 간 + workspace 간) | 06 Q16 |
| 4 모듈 | 4a 모듈 생성 | 04-S1 | |
| | 4b 모듈 사용 | 04-S2 | 04-S1 |
| | 4c 모듈 리팩터링·버저닝 | 04-S3 | |
| | 4d 기존 구성 → 모듈 | 04-S1 | |
| 5 provider | 5a 플러그인 아키텍처 | 05-S3 | |
| | 5b alias·버전·소싱·업그레이드 | 05-S1 | 03-S1 |
| | 5c 인증 | 05-S2 | |
| | 5d provider 오류 | 05-S3 | 05-S2 |
| 6 HCP Terraform (객관식) | 6a run 워크플로 | 06 Q1–6, Q17 | |
| | 6b workspace·접근 관리 | 06 Q7–10, Q18–21 | |
| | 6c provider 자격 증명 | 06 Q11–13 | 05-S2 |
| | 6d 정책·거버넌스 | 06 Q14–16, Q22 | |

## 5. Terraform 1.6 함정표 (시험 환경에 없는 기능)

| 하고 싶은 일 | 1.6에서의 방법 | 쓰면 안 되는 것(도입 버전) |
|---|---|---|
| 리소스 관리 중단(실물 유지) | 블록 삭제 + `terraform state rm` | `removed` 블록 (1.7) |
| 여러 리소스 일괄 import | import 블록을 여러 개 작성 | import 블록 `for_each` (1.7) |
| 테스트에서 provider 대체 | 실제 provider + `command = plan` | `mock_provider`, `override_*` (1.7) |
| 변수 간 검증 | `precondition` | validation에서 다른 변수 참조 (1.9) |
| S3 backend 잠금 | `dynamodb_table` | `use_lockfile` (1.10) |
| state에 남지 않는 비밀 | 설계로 회피(런타임 조회) | `ephemeral` (1.10), write-only 인자 (1.11) |

## 6. 진행 방법

**준비물**: tfenv(또는 Terraform 1.6.6), AWS CLI v2, jq, git, (선택) vault CLI가 필요합니다.
- AWS는 **실습 전용 계정**의 관리자급 **IAM 사용자 또는 역할(SSO 포함)**로 실행하세요. 루트 사용자는 AssumeRole(05-S2)을 할 수 없습니다.
- us-east-1과 us-west-2에 **기본 VPC**가 있어야 합니다.
- 모든 Terraform 코드, 스크립트, 채점 명령은 us-east-1을 기준으로 합니다. 셸에서 먼저 아래를 설정하세요.

  ```bash
  export AWS_REGION=us-east-1 AWS_DEFAULT_REGION=us-east-1
  ```

- 명령 예시는 macOS(BSD `sed -i ''`) 기준입니다. Linux에서는 `sed -i`를 쓰세요.

**비용과 안전**
- 모든 리소스에 `Project=tf-adv-practice` 태그가 붙습니다(provider `default_tags`).
- 시나리오가 끝나면 반드시 `terraform destroy`를 실행하고 `scripts/leftovers.sh`로 남은 리소스를 확인하세요.
- EC2는 t3.micro/small만, 그리고 시나리오 진행 중에만 씁니다.

**권장 순서**: 01 → 02 → 03 → 04 → 05 → 06. 03-S3은 03-S2 bootstrap을 재사용하므로, bootstrap은 03-S3 정리 단계에서 지웁니다. 시나리오별 시간은 각 README에 있습니다(20~40분).

**풀이 규칙(시험 재현)**
- 시험 중에는 Terraform 문서, 제한된 Registry, 제한된 클라우드 provider 문서, **AWS 콘솔**만 쓸 수 있고 검색 엔진은 쓸 수 없습니다. 실습도 각 README의 "참고 문서", registry 문서, AWS 문서와 콘솔만 보고 푸세요. `SOLUTION.md`는 채점할 때만 엽니다.
- 시험은 US QWERTY 원격 환경이고 개인 단축키를 쓸 수 없습니다. 에디터는 `vi`/`nano`로 연습하세요.

**모의고사(4시간)**: 영역별로 시나리오 1개씩 골라 Lab 5개(01-S1, 02-S3, 03-S2, 04-S1, 05-S1)를 약 3시간 안에 풀고, 06 문항 22개를 25분 안에 푸세요. Lab은 독립 채점이므로 막히면 다음 Lab으로 넘어갑니다.

## 7. 검증 기록
평가 축, 점수 체계, 라운드별 반박과 반영 내역은 [EVALUATION.md](EVALUATION.md)에 있습니다.

## 부록 A. 지정 URL (Pro 002) 항목 대응표

요청에서 지정한 Infrastructure Engineer Professional(002) 40개 항목을 이 실습에 대조했습니다. ✗는 HCTOA(1.6) 범위 밖이라 **의도적으로 제외**한 항목입니다.

| 영역 | 커버 | 범위 밖(✗) / 부분(△) |
|---|---|---|
| 1 설계 (1a–1h) | 1a 02-S3·04-S1, 1b 04-S1·01-S4, 1c·1e 02-S3(퀴즈), 1d 02-S3·01-S4, 1f 02-S1·02-S3·02-S4, 1g 05-S1·03-S1 | ✗ 1h Terraform MCP server |
| 2 state·backend (2a–2e) | 2a 03-S2·03-S3, 2b 01-S2, 2c 03-S1·05-S3, 2d 03-S1, 2e 01-S4 | △ 2a `use_lockfile`(1.10), 2c `removed` 블록(1.7) |
| 3 수명주기·운영 (3a–3i) | 3a 04-S1·03-S3, 3b 01-S2·01-S3, 3c 01-S3·03-S2, 3d 01-S1, 3e 01-S4·02-S4, 3f 03-S3, 3g 05-S3·03-S2, 3h 03-S3·02-S2, 3i 03-S1·04-S2 | △ 3c provisioner, 3g `timeouts`·`state push` |
| 4 CI/CD (4a–4d) | 4a·4b 03-S2, 4c 05-S2·06 Q11–12, 4d 02-S3(9) | |
| 5 보안·거버넌스 (5a–5e) | 5a 02-S5, 5c 05-S2, 5d 06 Q14–15, 5e 02-S4·01-S3 | △ 5b 비밀 회전(02-S5 서술만), ✗ `ephemeral`(1.10) |
| 6 모듈 (6a–6d) | 6a·6b 04-S1·04-S3, 6c 04-S2, 6d 02-S1 | ✗ 6d mocks(1.7) |
| 7 HCP Terraform (7a–7e) | 7a 06 Q1–6, 7c 06 Q10, 7e 06 Q14–15 | ✗ 7b 비용 추정, △ 7d workspace별 버전 업그레이드 |
