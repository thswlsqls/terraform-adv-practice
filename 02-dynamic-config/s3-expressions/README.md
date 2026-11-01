# 02-S3. CSV 입력으로 동적 보안 그룹 만들기

- 목표: **2c** HCL 함수 · **2e** 복합 타입 변수/출력 (+ 2d for_each, dynamic)
- 형태: Lab + 값 예측 퀴즈 · 권장 35분 · 비용: 없음 (SG만)

## 상황
보안팀은 방화벽 규칙을 `rules.csv`로 관리합니다. CSV 한 줄이 Terraform 규칙 하나가 되어야 하고, 줄을 추가하거나 삭제해도 **다른 규칙은 건드리지 않아야** 합니다.

## 과제
1. `rules.csv`를 읽어 규칙 이름을 키로 하는 맵 `local.rules`를 만드세요.
2. `aws_security_group.app`을 만들고, `var.egress`의 각 항목을 **`dynamic` 블록**으로 egress 규칙으로 만드세요. description이 없는 항목은 `optional()` 기본값을 씁니다.
3. ingress는 `aws_vpc_security_group_ingress_rule`을 `for_each`로 만드세요(CSV의 `port`는 문자열입니다).
4. `local.tags`는 `var.default_tags`에 `Env = var.env`를 **덮어써서** 만들고, SG와 규칙에 적용하세요.
5. 인스턴스 타입을 `var.instance_type_by_env`에서 조회하되, 없으면 `t3.micro`를 쓰세요. 결과는 `instance_type` 출력으로 내보내세요.
6. `var.vpc_cidr`를 /20 서브넷 4개로 나눈 목록을 `subnet_cidrs` 출력으로 내보내세요.
7. 출력을 만드세요.
   - `rules`: `{ <name> = { port = number, cidr = string } }` 형태의 맵
   - `public_rules`: `public`이 true인 규칙 이름의 정렬된 목록
   - `user_data`: `user_data.tftpl`에 env와 정렬된 포트 목록을 넣어 렌더링한 결과
8. `quiz.md`의 20문항을 풀고 `terraform console`로 채점하세요.
9. **변수 우선순위**: 아래처럼 4곳에서 `env`를 지정했을 때 `terraform output instance_type`의 결과를 먼저 예측한 뒤 확인하세요. 마지막으로 4개를 하나씩 지워 가며 순서를 확정하세요.
   ```bash
   echo 'env = "stg"'  > terraform.tfvars
   echo 'env = "prod"' > prod.auto.tfvars
   echo 'env = "qa"'   > qa.tfvars
   export TF_VAR_env=dev
   terraform apply -var-file=qa.tfvars -auto-approve
   ```

## 채점 기준
```bash
terraform apply -auto-approve
terraform output -json rules | jq -e '.ssh.port == 22 and .https.cidr == "0.0.0.0/0"'
terraform output -json public_rules        # ["https"]
terraform output -json subnet_cidrs        # ["10.20.0.0/20","10.20.16.0/20","10.20.32.0/20","10.20.48.0/20"]
terraform output instance_type             # "t3.micro"  (-var env=prod 이면 "t3.small")
# CSV에서 ssh 줄 삭제 후:
terraform plan                             # 1 to destroy 만 (나머지 규칙 변화 없음)
```
퀴즈는 18/20 이상이면 통과입니다. 9번 결과는 `t3.micro`(env=qa)입니다.

## 정리
`terraform destroy`

## 참고 문서
- https://developer.hashicorp.com/terraform/language/functions
- https://developer.hashicorp.com/terraform/language/expressions/for
- https://developer.hashicorp.com/terraform/language/expressions/dynamic-blocks
- https://developer.hashicorp.com/terraform/language/expressions/type-constraints#optional-object-type-attributes
