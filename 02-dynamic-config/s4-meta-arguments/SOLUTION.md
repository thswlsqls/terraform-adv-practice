# 02-S4 해설

정답 코드는 `solution/main.tf`에 있습니다.

- 1: 기본 교체 순서는 destroy 후 create(`-/+`)입니다. 이 순서에서는 새 SG가 생기기 전에 옛 SG가 사라져 LT가 잠시 없는 SG를 가리키게 됩니다. `create_before_destroy`(`+/-`)를 쓰면 고정 `name`이 새 SG와 겹치므로 `name_prefix`로 바꿔야 합니다. LT는 새 SG ID로 **새 버전**만 만들 뿐, 옛 SG 삭제를 막지 않습니다. 삭제를 막는 것(`DependencyViolation`)은 옛 SG를 쓰는 **인스턴스 ENI**나 다른 SG의 참조입니다. 그래서 이 문제는 ASG를 0대에서 시작합니다. 운영에서는 인스턴스를 먼저 교체한 뒤(instance refresh) 옛 SG를 정리하세요.
- CBD는 이 리소스가 **의존하는 리소스(dependencies)** 쪽으로 자동 전파됩니다. A에 CBD를 켜고 A가 B에 의존하면, B에도 CBD가 적용됩니다.
- 2: `ignore_changes = [desired_capacity]`로 해결합니다. 외부 오토스케일링 정책과 공존하는 표준 패턴입니다.
- 3: `prevent_destroy`는 해당 리소스를 파괴하는 **plan 자체를 오류로** 만듭니다. 블록을 config에서 지우면 보호도 함께 사라지므로 IAM이나 S3 Object Lock 같은 계층적 보호와 같이 써야 합니다.
- 4: `one(aws_instance.bastion[*].id)`는 원소가 0개면 `null`, 1개면 그 값을 냅니다. `aws_instance.bastion[0].id`를 쓰면 count가 0일 때 오류가 납니다. 값이 null인 루트 출력은 state에 저장되지 않으므로 `terraform output bastion_id`는 `not found` 오류를 냅니다(값을 확인하려면 `terraform console`).
- 6: `aws_security_group_rule`은 규칙 하나를 별도 리소스로 관리합니다. 같은 SG에 인라인 `ingress` 블록을 함께 쓰면 서로 덮어쓰므로 섞지 마세요. 신규 코드는 `aws_vpc_security_group_ingress_rule`(02-S3)이 권장됩니다.
- 7: `instance_refresh { strategy = "Rolling" }`는 LT 버전 변경 같은 ASG 설정 변경이 일어나면 인스턴스 교체를 시작합니다. 이것은 lifecycle이 아니라 리소스 인자입니다. Terraform은 교체 시작만 요청하고 완료를 기다리지 않습니다.
- 5: `replace_triggered_by`는 **관리 리소스(또는 그 속성) 참조만** 받습니다. 변수를 직접 넣을 수 없어서 `terraform_data`(1.4+)로 감쌉니다.
- `depends_on`은 02-S2 과제 7에서 다룹니다.
- `provider` 메타 인자는 05-S1에서, 모듈의 `count`/`for_each`는 04-S1에서 다룹니다.
