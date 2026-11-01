# 01-S2 해설

```bash
terraform plan -refresh-only        # 1. 드리프트만 표시하고 인프라는 바꾸지 않는다
terraform apply -refresh-only       # 2. state만 실제 값으로 갱신 (terraform refresh는 deprecated, 확인 절차 없음)
terraform plan                      # 3. 설정과 state를 비교: Owner를 platform으로, 22 규칙 제거, object 생성
```

- 1에서 `aws_s3_object.config`는 "has been deleted"로 표시됩니다. SG는 tags/ingress 변경으로 나옵니다.
- 2를 마치면 state에서 object가 사라집니다. 3의 일반 plan은 설정을 기준으로 **원복**을 계획합니다(태그 되돌림, 22 규칙 제거, object 생성).
- 4: `main.tf`의 `Owner = "security-team"`으로 바꾼 뒤 apply하면 22 규칙 제거와 object 재생성만 진행됩니다. 인라인 `ingress`는 SG 규칙 전체를 권위 있게(authoritative) 관리하므로, 코드에 없는 규칙은 지워집니다.
- `-refresh-only`와 `-refresh=false`를 구분하세요. `-refresh=false`는 드리프트 확인을 **건너뛰는** 옵션입니다(대규모 state에서 속도를 높일 때).
- 승인되지 않은 드리프트를 반복해서 막으려면 IAM 권한 축소, HCP Terraform health assessment(드리프트 감지) 같은 운영 통제가 함께 필요합니다.
