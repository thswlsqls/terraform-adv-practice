# 05. provider 핵심 정리

목표 5(5a 플러그인 구조 · 5b 구성·alias · 5c 인증 · 5d 오류 진단)에서 S1~S3를 풀며 익혀야 할 내용입니다. 환경은 Terraform 1.6, AWS provider 5.x 기준입니다.

## 1. provider 구성과 alias (S1)

| 위치 | 선택 방법 | 예시 |
|---|---|---|
| 루트 리소스·data source | `provider` 생략 시 기본 구성, 다른 리전은 명시 | `provider = aws.dr` |
| 자식 모듈 | `required_providers`에 alias 선언 | `configuration_aliases = [aws.src, aws.dst]` |
| 모듈 호출부 | 부모의 구성을 자식 alias에 매핑 | `providers = { aws.src = aws, aws.dst = aws.dr }` |

- 같은 이름 필터의 AMI도 리전마다 ID가 다릅니다. `aws_ami`를 리전별 provider로 각각 조회하세요.
- 여러 provider 구성을 받는 모듈은 provider 블록을 직접 만들지 않고 호출자가 전달합니다. 모듈 내부의 리소스와 data source에는 어느 alias를 쓸지 명시합니다.
- 기본 provider를 지우면 생략한 리소스는 빈 기본 구성 또는 환경의 리전 설정을 사용하려 합니다. state에 기록된 구성을 제거하면 기존 리소스를 관리하거나 파괴할 때 `Provider configuration not present`가 날 수 있으므로, 리소스를 옮기거나 제거한 뒤 provider 구성을 지웁니다.

## 2. 교차 리전 S3 복제 (S1)

1. src·dst 버킷 양쪽의 versioning을 켭니다.
2. S3 서비스가 assume할 IAM 역할에 src 버킷·객체 읽기와 dst 객체 복제 권한을 줍니다. 버킷 ARN과 `/*` 객체 ARN을 구분합니다.
3. src provider로 `aws_s3_bucket_replication_configuration`을 만들고 양쪽 versioning에 `depends_on`을 둡니다. 복제 설정 이후 업로드한 객체로 확인합니다. 기존 객체에는 별도 Batch Replication이 필요합니다.

복제 설정이 존재하는 것과 실제 복제가 끝난 것은 다릅니다. 목적지 객체의 `ReplicationStatus = REPLICA`까지 확인하세요.

## 3. 자격 증명과 AssumeRole (S2)

```text
코드 밖의 기본 자격 증명 → STS AssumeRole → 제한된 배포 역할로 AWS API 호출
```

- 탐색 경로: provider 인자(하드코딩 비권장) → 환경 변수 → 공유 credentials/config 파일·프로필 → ECS 자격 증명 → EC2 인스턴스 프로필. 실제 선택에는 명시한 `profile` 등의 설정이 영향을 줍니다.
- `assume_role { role_arn = var.role_arn; session_name = "tfadv-deploy" }`은 먼저 찾은 자격 증명으로 STS를 호출합니다. 역할 생성과 사용을 별도 root 구성(`role/`, `deploy/`)으로 분리하면 provider 구성에서 아직 모르는 리소스 값을 참조하지 않아도 됩니다.
- `aws_caller_identity.arn`은 `assumed-role/.../tfadv-deploy` 세션 ARN입니다. `aws_iam_session_context.issuer_arn`은 원래 역할 ARN이고 조회에 `iam:GetRole` 권한이 필요합니다.
- `AccessDenied`는 **주체 ARN → API 동작 → 대상 리소스 ARN** 순서로 읽고 역할 정책과 대조합니다. S2의 금지된 버킷 생성은 역할의 S3 리소스 패턴 밖이므로 실패합니다.
- CI에서는 OIDC 웹 자격 증명이나 HCP Terraform dynamic provider credentials로 단기 자격 증명을 발급할 수 있습니다. 장기 키를 `.tf`나 변수 파일에 넣지 않습니다.

## 4. 플러그인 설치와 오류 진단 (S3)

| 단계 | 확인할 오류 | 조치 |
|---|---|---|
| `init` | 루트 `~> 5.0`과 모듈 `>= 6.0`의 교집합 없음 | `terraform providers`로 제약의 출처를 확인하고 호환 범위로 수정 |
| `validate` | `Provider configuration not present` | 실제로 빠진 `aws.eu` alias를 선언하고 region·기본 태그 설정 |
| `plan` | `invalid AWS Region: us-east-9` | region 오타 수정 |

- provider는 `.terraform/providers/<host>/<namespace>/<type>/<version>/<os_arch>/`의 별도 실행 파일이며 Terraform 코어와 플러그인 프로토콜로 통신합니다. `terraform providers`는 구성과 state의 provider 요구 사항을 보여 줍니다.
- 플랫폼별 lock checksum이 빠졌다면 `terraform providers lock -platform=darwin_arm64 -platform=linux_amd64`로 필요한 플랫폼 해시를 추가합니다. 반복 다운로드를 줄이려면 CLI 설정의 `plugin_cache_dir` 또는 `TF_PLUGIN_CACHE_DIR`를 사용합니다.
- provider 로그만 볼 때는 `TF_LOG_PROVIDER=DEBUG TF_LOG_PATH=provider.log terraform plan`을 실행합니다. `TF_LOG`는 코어까지 포함하는 전체 로그입니다. 로그에는 자격 증명 등이 포함될 수 있으므로 공유 전에 내용을 확인합니다.

## 5. 자주 틀리는 포인트

- alias는 선언만으로 리소스에 자동 적용되지 않습니다. 리소스·data source의 `provider` 또는 모듈 호출의 `providers` 매핑이 필요합니다.
- `depends_on`은 참조만으로 순서가 보장되지 않는 복제 설정과 versioning 같은 경우에 사용합니다.
- 오류 메시지의 "configuration removed"가 실제 삭제를 뜻한다고 단정하지 않습니다. S3에서는 선언하지 않은 alias가 원인이었습니다.
- S3 실습 후에는 복제 버킷의 객체를 포함해 `terraform destroy`하고 잔여 리소스를 점검합니다.
