# 04-S1. 모놀리스를 모듈로 리팩터링 (무중단)

- 목표: **4a** 모듈 생성 · **4d** 기존 구성을 모듈로 리팩터링 (+ 2d 모듈 for_each)
- 형태: Lab · 권장 40분 · 비용: t3.micro 2대

## 상황
`main.tf`에는 웹 서버 1대(SG, 규칙, EC2)가 루트에 직접 정의되어 있습니다. 같은 구성을 `blue`/`green` 두 벌로 운영하려 합니다.
**기존 인스턴스(blue)는 교체되면 안 됩니다.**

## 준비
```bash
terraform init && terraform apply -auto-approve
terraform state show aws_instance.web | grep -E '^\s+id ' > before-id.txt
```

## 과제
1. `modules/web-server/`를 표준 모듈 구조(`main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`)로 만드세요.
   - 입력: `name`, `subnet_id`, `ami_id`, `instance_type`(기본 `t3.micro`), `ingress_ports`(기본 `[80]`). 모든 변수에 `type`과 `description`을 붙이세요.
   - 출력: `instance_id`, `public_ip`, `security_group_id`
   - 모듈 안에 `provider` 블록을 두지 마세요. `required_providers`만 선언합니다.
2. 루트에서 `module "web"`을 `for_each`로 `blue`, `green` 두 벌 호출하세요.
3. 기존 리소스 3개를 `module.web["blue"]` 아래로 옮기세요. **CLI state 명령은 쓰지 마세요.**
4. plan이 `blue`의 SG나 인스턴스를 교체하려 한다면 그 원인을 찾아 없애세요(힌트: `moved`는 주소만 옮깁니다).
5. 루트 출력 `web_public_ips`를 `{ blue = "...", green = "..." }` 형태로 만드세요.

## 채점 기준
```bash
terraform plan    # blue: "has moved to" 3건 / 합계: 3 to add (green), 0 to destroy
terraform apply -auto-approve
terraform state show 'module.web["blue"].aws_instance.this' | grep -E '^\s+id '   # before-id.txt와 동일
terraform state list | grep -c '^aws_'      # 0 (루트에 리소스 없음, data 제외)
grep -rn 'provider "aws"' modules/          # 출력 없음
terraform output web_public_ips
```

## 정리
`terraform destroy`

## 참고 문서
- https://developer.hashicorp.com/terraform/language/modules/develop/structure
- https://developer.hashicorp.com/terraform/language/modules/develop/refactoring
- https://developer.hashicorp.com/terraform/language/modules/develop/providers
