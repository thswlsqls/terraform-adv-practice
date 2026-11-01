# 02-S2 해설

정답 코드는 `solution/main.tf`에 있습니다.

- `aws_ami`는 `owners`를 반드시 지정하세요. 빠뜨리면 같은 이름 패턴의 타인 공개 AMI가 선택될 수 있습니다. 결과가 여러 개면 `most_recent = true`가 필요하고, 그래도 0개면 plan이 오류로 끝납니다.
- `aws_subnet`은 결과가 **정확히 1개**여야 합니다. 0개나 여러 개면 오류입니다. 여러 개를 받으려면 `aws_subnets`(복수형)를 쓰세요.
- `aws_iam_session_context.issuer_arn`은 `assumed-role/...` ARN을 원래 역할 ARN으로 바꿔 줍니다. IAM 사용자라면 입력 ARN이 그대로 나옵니다.
- `aws_iam_policy_document`는 문법 검증, 조건 결합, `source_policy_documents` 병합을 지원하고, 키 순서가 정규화되어 불필요한 diff가 사라집니다. 대안은 `jsonencode()`입니다.
- 7: 인스턴스는 instance profile을 거쳐 role만 참조하므로, 정책 attachment와는 의존 관계가 없어 병렬로 생성될 수 있습니다. `depends_on = [aws_iam_role_policy_attachment.read_artifacts]`로 숨은 의존성을 명시하세요. `depends_on`은 이런 경우에만 쓰세요. 남용하면 plan에 `(known after apply)`가 늘어납니다.
- data source 인자가 apply 전에 알 수 없는 값에 의존하면 읽기가 apply 단계로 미뤄지고, 이를 참조하는 리소스는 plan에 `(known after apply)`로 표시됩니다.
