# 06 정답·해설

| Q | 정답 | 해설 · 근거 문서 |
|---|---|---|
| 1 | B | speculative plan은 apply가 불가능하고 결과가 VCS 상태 체크로 보고됩니다. merge되면 정상 run이 실행됩니다. (cloud-docs/run/ui) |
| 2 | `cloud` | 1.1+의 `cloud` 블록입니다. `workspaces`는 `name` 또는 `tags`로 지정하고, 1.6에서는 `TF_WORKSPACE` 환경 변수로도 고를 수 있습니다. (cloud-docs/run/cli) |
| 3 | B | `terraform init`이 기존 backend state를 HCP Terraform workspace로 이전합니다. (terraform/cli/cloud/migrating) |
| 4 | B | Run triggers는 소스 workspace의 apply 성공을 계기로 대상 workspace에 run을 queue합니다. (cloud-docs/workspaces/settings/run-triggers) |
| 5 | A | Run tasks는 pre-plan, post-plan, pre-apply, post-apply 단계에 연결해 외부 서비스를 호출합니다. enforcement가 mandatory이면 실패 시 run이 멈추고, advisory이면 경고만 냅니다. Run triggers는 workspace 간 연쇄 실행 기능입니다. (cloud-docs/workspaces/settings/run-tasks) |
| 6 | B | configuration version을 만들고 tar.gz를 업로드한 뒤 run을 생성합니다. (cloud-docs/run/api) |
| 7 | A | Local 실행 모드에서는 원격 실행 없이 state 저장만 HCP Terraform이 맡습니다. (cloud-docs/workspaces/settings#execution-mode) |
| 8 | `agent pool` (HCP Terraform agents) | 사설망 안의 agent가 outbound로 run을 받아 실행합니다. (cloud-docs/agents) |
| 9 | B | Plan 권한은 run을 queue하고 plan할 수 있지만 apply 승인은 할 수 없습니다. Write부터 apply가 가능합니다. (cloud-docs/users-teams-organizations/permissions) |
| 10 | D | priority variable set은 workspace 변수와 CLI `-var`까지 덮어씁니다. 그다음 순서는 workspace 변수 > project varset > global varset입니다. (cloud-docs/variables#precedence) |
| 11 | A, C | `TFC_AWS_PROVIDER_AUTH`와 `TFC_AWS_RUN_ROLE_ARN`(phase별로 `TFC_AWS_PLAN_ROLE_ARN`/`TFC_AWS_APPLY_ROLE_ARN`도 가능)입니다. audience 기본값은 `aws.workload.identity`입니다. (cloud-docs/workspaces/dynamic-provider-credentials/aws-configuration) |
| 12 | B | 신뢰 정책에서 `sub` 클레임을 조직/프로젝트/workspace/run_phase로 좁히세요. 조건이 없으면 같은 OIDC provider를 쓰는 다른 조직의 run도 역할을 assume할 수 있습니다. |
| 13 | A | workspace 변수의 sensitive 표시는 UI·API에서 write-only로 만들 뿐입니다. "Terraform runs receive the full text of all Terraform variable values, including sensitive ones." 출력 마스킹은 구성의 `sensitive = true`가 담당합니다. (cloud-docs/variables/managing-variables) |
| 14 | `soft-mandatory` | advisory는 경고만, soft-mandatory는 override 가능, hard-mandatory는 override 불가입니다. OPA는 advisory와 mandatory만 있습니다. (sentinel/docs/concepts/enforcement-levels) |
| 15 | A, B | 정책은 plan(과 cost estimation) **이후**에 평가됩니다. OPA에는 soft-mandatory가 없습니다. (cloud-docs/policy-enforcement) |
| 16 | A | `tfe_outputs`는 출력만 읽고 값을 sensitive로 표시합니다. 소스 workspace의 remote state sharing 설정에서 접근을 허용해야 합니다. (registry tfe provider, cloud-docs/workspaces/state) |
| 17 | `Allow empty apply` | 변경이 없는 apply를 허용하는 run 모드입니다. Terraform 업그레이드 후 state를 새 형식으로 다시 쓸 때 씁니다. (cloud-docs/run/modes-and-options) |
| 18 | A | Auto apply는 성공한 plan(정책·run task 통과)을 확인 없이 apply합니다. speculative plan은 원래 apply할 수 없습니다. (cloud-docs/workspaces/settings#auto-apply) |
| 19 | A, B | 작업 디렉터리는 Terraform을 실행할 위치이고, 트리거 경로 설정은 어떤 파일 변경이 run을 시작할지 정합니다. (cloud-docs/workspaces/settings/vcs) |
| 20 | B | 원격 실행의 버전은 workspace 설정이 결정합니다. 구성의 `required_version`은 그 버전을 허용해야 하고, 맞지 않으면 실패합니다. (cloud-docs/workspaces/settings#terraform-version) |
| 21 | B | project 수준 팀 권한은 그 project의 현재·미래 workspace 전체에 적용됩니다. owners는 과도한 권한이고, 토큰 공유는 금지 사항입니다. (cloud-docs/users-teams-organizations/permissions) |
| 22 | `sentinel.hcl` | `policy "name" { source = "./x.sentinel"  enforcement_level = "hard-mandatory" }` 형식입니다. OPA 정책 세트는 `policies.hcl`을 씁니다. (cloud-docs/policy-enforcement/manage-policy-sets) |
