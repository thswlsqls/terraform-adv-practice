# 03-S3. 구성 간 데이터 공유와 workspace별 환경

- 목표: **3d** 구성·workspace 간 데이터 공유 (+ 3b, 2b)
- 형태: Lab · 권장 35분 · 비용: t3.micro 1대(dev) + t3.small 1대(prod)
- 선행: 03-S2 `bootstrap`이 apply된 상태 (state 버킷 + 잠금 테이블)

## 상황
네트워크팀(`network/`)과 앱팀(`app/`)은 state를 따로 관리합니다. 앱팀은 네트워크 출력값으로 인스턴스를 배치하고,
같은 코드로 CLI workspace `dev`/`prod`를 운영합니다.

## 과제
1. `network/`를 공통 `backend.hcl`로 초기화한 뒤 apply하세요.
2. `app/`에서 `terraform_remote_state`로 network state를 읽으세요. `vpc_id`, `subnet_ids`, `app_sg_id`를 하드코딩 없이 쓰고, 버킷은 `var.state_bucket`으로 받습니다.
3. workspace `dev`와 `prod`를 만드세요. `terraform.workspace`에 따라 instance_type은 dev `t3.micro`, prod `t3.small`, Name 태그는 `app-<workspace>`로 설정하고, 두 workspace 모두 apply하세요.
4. S3에서 workspace별 state 객체 경로를 확인하고 `answers.txt`에 적으세요.
5. **workspace 간 조회**: `app`에 출력 `instance_id`를 추가하세요. **prod workspace에서만** dev workspace의 app state를 읽어 출력 `dev_instance_id`로 내보내세요. dev에서는 이 조회를 하지 않습니다. **dev → prod 순서로** 다시 apply하세요(prod가 dev의 새 출력을 읽기 때문).
6. **결합도 낮추기**: `app_sg_id`는 remote state 대신 **태그로 조회하는 data source**로 바꾸세요(`Tier = app`). 그런 다음 아래 질문에 답하세요.
   - `terraform_remote_state`가 보안상 문제가 될 수 있는 이유는 무엇인가요?
   - HCP Terraform을 쓸 때의 대안 data source는 무엇인가요?

## 채점 기준
```bash
cd app
terraform workspace list                      # default, dev, prod
grep -nE 'subnet-|sg-|vpc-' *.tf              # 출력 없음
aws s3 ls "s3://<bucket>/env:/" --recursive   # env:/dev/share-app/terraform.tfstate, env:/prod/share-app/terraform.tfstate
aws ec2 describe-instances --filters Name=tag:Name,Values=app-dev,app-prod Name=instance-state-name,Values=running \
  --query 'Reservations[].Instances[].[Tags[?Key==`Name`]|[0].Value,InstanceType]' --output text
# app-dev t3.micro / app-prod t3.small
terraform workspace select prod && terraform plan -detailed-exitcode -var state_bucket=<bucket>; echo $?   # 0
terraform output dev_instance_id      # dev workspace의 instance_id와 동일
terraform workspace select dev && terraform output instance_id
```

## 정리
`app`: **prod → dev** 순서로 `terraform destroy` (prod가 dev state를 읽으므로) → `network`: `terraform destroy` → `../s2-remote-state/bootstrap`: `terraform destroy`

## 참고 문서
- https://developer.hashicorp.com/terraform/language/state/remote-state-data
- https://developer.hashicorp.com/terraform/language/state/workspaces
- https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/data-sources/outputs
