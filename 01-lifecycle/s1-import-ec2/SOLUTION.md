# 01-S1 해설

정답 코드는 `solution/`에 있습니다.

```hcl
# imports.tf — 1.6부터 id에 plan 시점에 알 수 있는 표현식(변수 등)을 쓸 수 있다
import {
  to = aws_security_group.legacy
  id = var.sg_id
}

import {
  to = aws_instance.legacy
  id = var.instance_id
}
```

```bash
terraform plan -generate-config-out=generated.tf   # 대상 파일이 이미 있으면 오류
terraform validate                                 # 생성 코드가 실패하는 경우가 흔하다
```

정리 포인트
- 생성된 `aws_instance`는 provider 버전에 따라 서로 충돌하는 인자(예: `ipv6_address_count`와 `ipv6_addresses`)를 함께 넣는 경우가 있습니다. 오류 메시지에 나온 한쪽을 지우세요.
- `vpc_security_group_ids = ["sg-..."]`를 `[aws_security_group.legacy.id]`로 바꾸세요. 의존성이 생기고 하드코딩이 사라집니다.
- `ami`, `subnet_id` 같은 ForceNew 인자는 실제 값 그대로 두세요. 바꾸면 import 직후 교체(replace)가 계획됩니다.
- 생성된 SG 코드는 인라인 `ingress`/`egress`를 씁니다. 같은 SG에 `aws_vpc_security_group_ingress_rule`을 섞으면 서로 덮어쓰니 섞지 마세요.
- import 블록은 apply한 뒤 지워도 됩니다. 남겨 둬도 이미 state에 있으면 no-op입니다.
- CLI 대안은 `terraform import aws_instance.legacy i-...`입니다. 리소스 블록을 먼저 써야 하고 plan 미리보기가 없어서, 리뷰 가능한 import 블록 방식을 권장합니다.
- 1.6에서는 `import` 블록에 `for_each`를 쓸 수 없습니다(1.7+).
