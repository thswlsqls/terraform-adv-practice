# 06. HCP Terraform 객관식·빈칸 문항 22개 (목표 6a–6d, 객관식 전용)

공식 콘텐츠 목록상 영역 6은 **객관식 전용**입니다. 실제 시험처럼 빈칸 문제는 철자까지 정확해야 정답입니다.
정답과 해설은 `ANSWERS.md`에 있습니다. 권장 시간은 25분입니다.

### 6a. 실행 워크플로
**Q1.** VCS 연결 workspace에서 기본 브랜치로 향하는 PR을 열면 HCP Terraform은 무엇을 하나요?
- A. plan 후 자동 apply
- B. apply할 수 없는 speculative plan을 실행하고 결과를 PR 상태 체크로 보고
- C. 아무것도 하지 않음 (merge 후에만 실행)
- D. 새로운 workspace를 생성

**Q2.** 로컬 CLI에서 HCP Terraform workspace로 원격 실행(CLI-driven run)을 하려고 합니다. `terraform { ___ { organization = "acme"  workspaces { name = "app-prod" } } }`의 빈칸에 들어갈 블록 이름은? (빈칸)

**Q3.** 기존 S3 backend state를 HCP Terraform으로 옮기는 올바른 절차는?
- A. `terraform state push`로 직접 업로드
- B. backend 블록을 `cloud` 블록으로 바꾸고 `terraform init`을 실행해, state 이전 질문에 동의
- C. workspace를 새로 만들고 모든 리소스를 import
- D. `terraform login` 후 `terraform apply`

**Q4.** 네트워크 workspace가 apply를 성공하면 그 workspace를 소비하는 앱 workspace에서 run이 자동으로 queue되게 하려 합니다. 어떤 기능을 쓰나요?
- A. Run tasks
- B. Run triggers
- C. Notification
- D. Agent pools

**Q5.** plan이 끝난 뒤 apply 전에 외부 보안 스캐너를 호출하고, 스캐너가 실패를 반환하면 run을 멈추게 하려 합니다. 어떤 기능을 쓰나요?
- A. Run tasks (post-plan 단계, enforcement mandatory)
- B. Run triggers
- C. Notification configuration
- D. Health assessments

**Q6.** 다음 중 API-driven run workflow에 대한 설명으로 옳은 것은?
- A. VCS 웹훅 없이는 run을 만들 수 없다
- B. 구성 파일을 tar.gz로 묶어 configuration version으로 업로드한 뒤 run을 생성한다
- C. state 파일만 업로드하면 plan이 실행된다
- D. CLI가 반드시 필요하다

### 6b. workspace와 접근 관리
**Q7.** HCP Terraform workspace의 execution mode를 **Local**로 바꾸면?
- A. plan/apply가 로컬 머신에서 실행되고 HCP Terraform은 state 저장과 잠금만 담당
- B. run이 agent pool에서 실행
- C. state가 로컬 파일로 이동
- D. VCS 연결이 필수

**Q8.** 사설망 안의 리소스(예: 내부 vSphere)를 관리하는 workspace를 실행하려 합니다. 무엇을 사용하나요? (빈칸, 영어 2단어)

**Q9.** 한 팀에 특정 workspace의 plan 실행 권한은 주되 apply는 막고 싶습니다. 적절한 workspace 고정 권한 수준은?
- A. Read
- B. Plan
- C. Write
- D. Admin

**Q10.** 변수 우선순위가 가장 높은 것은? (다른 설정은 모두 같은 키를 정의한다고 가정)
- A. global(조직 전체) variable set
- B. project에 적용된 variable set
- C. workspace 고유 변수
- D. priority로 지정된 variable set

### 6c. provider 자격 증명
**Q11.** AWS dynamic provider credentials를 활성화하는 workspace **환경 변수** 두 개를 고르세요.
- A. `TFC_AWS_PROVIDER_AUTH = true`
- B. `AWS_ACCESS_KEY_ID`
- C. `TFC_AWS_RUN_ROLE_ARN = arn:aws:iam::...:role/...`
- D. `TF_VAR_role_arn`

**Q12.** dynamic credentials용 IAM 역할의 신뢰 정책에서 특정 workspace의 run만 허용하려면 어떤 OIDC 클레임 조건을 거나요?
- A. `app.terraform.io:aud = organization:...`
- B. `app.terraform.io:sub` 를 `organization:<ORG>:project:<PROJECT>:workspace:<WS>:run_phase:*` 패턴으로 제한
- C. `aws:SourceIp` 를 HCP Terraform IP로 제한
- D. 조건 없이 Principal 만 지정

**Q13.** workspace 변수를 sensitive로 표시하면?
- A. UI·API에서 값을 다시 읽을 수 없다(write-only). 하지만 run에는 원문이 전달되므로, 구성이 그 값을 출력이나 리소스 인자로 쓰면 로그와 state에 남을 수 있다
- B. state에서도 제거된다
- C. Terraform 변수에만 적용 가능하고 환경 변수에는 불가
- D. 구성에 `sensitive = true`가 없어도 plan 출력에서 항상 마스킹된다

### 6d. 정책과 거버넌스
**Q14.** Sentinel 정책 enforcement level 중 **권한 있는 사용자가 실패를 override할 수 있는** 것은? (빈칸, 하이픈 포함)

**Q15.** 정책 세트(policy set)에 대한 설명으로 옳은 것을 2개 고르세요.
- A. 조직 전체 또는 특정 project/workspace에 적용할 수 있다
- B. VCS 저장소에서 정책을 가져올 수 있다
- C. plan 이전에 평가된다
- D. OPA 정책의 enforcement level에는 soft-mandatory가 있다

**Q16.** 다른 workspace의 출력값을 읽을 때 `terraform_remote_state` 대신 권장되는 data source와, 소스 workspace에서 필요한 설정은?
- A. `tfe_outputs` / 소스 workspace의 "Remote state sharing"에서 소비 workspace 허용
- B. `tfe_workspace` / 소비 workspace를 admin 팀에 추가
- C. `terraform_remote_state` 만 가능
- D. `tfe_variables` / 변수 공유 활성화

### 추가 문항
**Q17. (6a)** workspace의 Terraform 버전을 올린 뒤, 리소스 변경 없이 state를 새 형식으로 다시 기록하는 apply를 하고 싶습니다. plan에 변경이 없어도 apply할 수 있게 하는 run 옵션은? (빈칸, UI 표기)

**Q18. (6b)** workspace의 **Auto apply** 설정에 대한 설명으로 옳은 것은?
- A. 성공한 plan을 확인 없이 apply한다. 단, PR의 speculative plan은 apply하지 않는다
- B. 모든 PR의 plan을 자동 apply한다
- C. 정책 검사가 실패해도 apply한다
- D. CLI-driven workspace에서는 설정할 수 없다

**Q19. (6b)** 모노레포에서 `infra/network/` 디렉터리만 다루는 VCS workspace가 다른 디렉터리 변경에도 run을 시작합니다. 설정할 workspace 옵션 2개를 고르세요.
- A. Terraform Working Directory = `infra/network`
- B. 자동 run 트리거를 경로 패턴/접두사 기준(`infra/network/**`)으로 제한
- C. Execution mode = Local
- D. Remote state sharing 비활성화

**Q20. (6b)** CLI-driven workspace에서 로컬 Terraform은 1.6.6이고, workspace 설정의 Terraform version은 1.5.7입니다. `terraform plan`은 어떤 버전으로 실행되나요?
- A. 로컬 1.6.6
- B. workspace 설정의 1.5.7 (원격 실행)
- C. 둘 중 높은 버전
- D. `required_version`이 결정

**Q21. (6b)** 플랫폼팀에 project `payments` 안의 workspace 30개(앞으로 추가될 것 포함)를 관리할 권한을 최소한의 운영 부담으로 주려 합니다. 가장 알맞은 방법은?
- A. workspace마다 팀 접근 권한을 추가
- B. project `payments`에 팀 권한(예: Maintain)을 부여
- C. 플랫폼팀을 owners 팀에 추가
- D. 조직 API 토큰을 공유

**Q22. (6d)** VCS 저장소에서 Sentinel 정책 세트를 가져올 때, 각 정책 파일과 enforcement level을 선언하는 설정 파일 이름은? (빈칸)
