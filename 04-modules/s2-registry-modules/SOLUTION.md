# 04-S2 해설

정답 코드는 `solution/main.tf`에 있습니다.

- `version = "~> 4.1"`은 `>= 4.1, < 5.0`입니다.
- 모듈의 `for_each` 결과는 `module.artifacts["dev"]`처럼 **키로 접근하는 맵**입니다. `for_each = module.artifacts`로 다른 리소스를 반복할 수 있습니다(키와 값은 모듈 출력 객체).
- 답변
  - 모듈 블록을 추가하거나 source·version을 바꾸면 `terraform init`(또는 `terraform get`)이 필요합니다. 이미 받은 모듈을 제약 범위 안의 최신으로 올리려면 `terraform init -upgrade`를 쓰세요.
  - `version` 인자는 **레지스트리 소스에서만** 유효합니다. Git 소스에 붙이면 init이 오류를 냅니다. Git 소스는 `?ref=v1.2.0`(태그·브랜치·커밋)으로 고정합니다.
  - 비공개 레지스트리 주소는 `app.terraform.io/<ORG>/<NAME>/<PROVIDER>`입니다(TFE는 자체 호스트명). 인증은 `terraform login`이나 CLI 설정 파일의 `credentials` 블록으로 합니다.
- 레지스트리 모듈은 lock 파일에 기록되지 않습니다. 재현성이 중요하면 정확한 버전(`= 4.1.2`)으로 고정하고, 의도한 시점에만 올리세요.
