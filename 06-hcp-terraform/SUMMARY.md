# 06. HCP Terraform 핵심 정리

목표 6(6a 실행 워크플로 · 6b workspace·접근 관리 · 6c provider 자격 증명 · 6d 정책·거버넌스)의 [22문항](questions.md)을 복습하기 위한 기록입니다. 정답별 설명은 [ANSWERS.md](ANSWERS.md)를 참고하세요.

## 1. 실행 워크플로 (Q1–6, Q17)

| 방식 | run을 시작하는 경로 | 기억할 점 |
|---|---|---|
| VCS 연결 | 저장소 이벤트 | PR은 apply할 수 없는 speculative plan, 기본 브랜치 변경은 일반 run |
| CLI-driven | `terraform { cloud { organization = ...; workspaces { name = ... } } }` | `terraform login` 후 CLI에서 실행 요청, 원격 실행이면 workspace의 Terraform 버전 사용 |
| API-driven | configuration version 생성 → tar.gz 업로드 → run 생성 | VCS 웹훅이나 로컬 CLI 없이 자동화 가능 |

- 기존 backend를 HCP Terraform으로 옮길 때 `cloud` 블록으로 바꾸고 `terraform init`에서 state 이전을 승인합니다.
- Run triggers는 **다른 workspace의 성공한 apply**를 계기로 run을 queue합니다. Run tasks는 run의 단계에서 **외부 서비스**를 호출합니다. post-plan의 mandatory task가 실패하면 run이 멈춥니다.
- `Allow empty apply`는 변경 없는 plan도 apply해 state를 다시 기록할 때 사용합니다.

## 2. workspace와 권한 (Q7–10, Q18–21)

| 설정 | 효과 |
|---|---|
| Execution mode: Local | plan/apply는 로컬에서 실행, HCP Terraform은 state 저장·잠금 담당 |
| Agent pool | 사설망에 연결된 agent가 run 실행 |
| Auto apply | 성공한 일반 plan을 승인 대기 없이 apply; speculative plan은 제외 |
| Working Directory + VCS 트리거 경로 | 모노레포에서 실행 위치와 run을 시작할 변경 범위를 각각 지정 |
| Project 팀 권한 | project의 현재·미래 workspace에 함께 적용 |

- workspace의 Plan 권한은 plan 실행까지이고 apply 승인은 할 수 없습니다. 여러 workspace에 같은 팀 권한이 필요하면 project 수준 권한을 검토합니다.
- 변수 우선순위의 핵심: **priority variable set > workspace 변수 > project variable set > global variable set**. CLI 인자와 충돌하는 경우도 priority set이 우선합니다.
- 원격 실행의 Terraform 버전은 workspace 설정을 따릅니다. 구성의 `required_version`과 맞지 않으면 실행이 실패합니다.

## 3. AWS 동적 자격 증명 (Q11–13)

- workspace 환경 변수 `TFC_AWS_PROVIDER_AUTH=true`와 `TFC_AWS_RUN_ROLE_ARN`으로 AWS dynamic provider credentials를 설정합니다. 필요하면 plan/apply 역할 ARN을 따로 지정합니다.
- AWS IAM 역할의 OIDC 신뢰 정책은 `app.terraform.io:sub`를 `organization:<ORG>:project:<PROJECT>:workspace:<WS>:run_phase:*`처럼 특정 workspace로 제한합니다.
- HCP Terraform 변수의 sensitive 표시는 UI·API에서 값을 다시 읽지 못하게 합니다. run에는 원문이 전달되므로 Terraform 구성에서 쓰인 값은 로그나 state에 남을 수 있습니다. 구성의 `sensitive = true`와 state 접근 통제를 별도로 확인합니다.

## 4. 정책과 데이터 공유 (Q14–16, Q22)

| 기능 | 핵심 구분 |
|---|---|
| Sentinel advisory | 실패해도 경고 |
| Sentinel soft-mandatory | 권한 있는 사용자가 실패 override 가능 |
| Sentinel hard-mandatory | 실패 override 불가 |
| OPA | advisory·mandatory (soft-mandatory 없음) |

- 정책 세트는 조직 또는 특정 project/workspace에 적용하고 VCS에서 가져올 수 있습니다. 정책 평가는 plan 이후입니다. VCS Sentinel 정책은 `sentinel.hcl`에 정책 파일과 enforcement level을 선언합니다.
- workspace 간 출력 공유에는 `tfe_outputs` data source를 쓰고 소스 workspace의 Remote state sharing에서 소비 workspace를 허용합니다.

## 5. 헷갈리는 조합

- **Run triggers**: workspace 사이 실행 연결 / **Run tasks**: 외부 검사 서비스 연결.
- **Local execution**: 실행 장소가 로컬 / **Agent execution**: agent pool에서 실행. 둘 다 HCP Terraform workspace의 state를 사용할 수 있습니다.
- **Auto apply**는 성공한 plan의 승인 단계 설정이고, **speculative plan** 자체는 apply 대상이 아닙니다.
- **sensitive workspace 변수**는 UI·API 재조회 제한이고, Terraform state에서 비밀이 사라진다는 뜻은 아닙니다.
