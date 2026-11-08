# 01. 리소스 수명주기 핵심 정리

목표 1(1a init · 1b plan · 1c apply · 1d destroy · 1e state·import·drift)에서 S1~S4를 풀며 익혀야 할 내용입니다. 환경은 Terraform 1.6 기준입니다.

## 1. 명령·옵션 한눈에 보기

| 단계 | 옵션 | 동작 | 시나리오 |
|---|---|---|---|
| init | `-backend=false` | backend 초기화 없이 provider·모듈만 설치. CI lint/validate용 | S3 |
| | `-upgrade` | lock 파일을 무시하고 제약 범위 안 최신 버전 설치, lock 갱신 | S3 |
| | `-reconfigure` / `-migrate-state` | backend 설정 변경 시 기존 state를 버리고 재설정 / 새 backend로 이전 | 03 |
| plan | `-out=FILE` | plan 저장. `terraform show -json FILE`로 기계 판독 | S3 |
| | `-refresh-only` | 실제 인프라와 state의 차이(드리프트)만 표시 | S2 |
| | `-refresh=false` | 드리프트 확인을 **건너뜀**(속도용). `-refresh-only`와 반대 의미 | S2 |
| | `-target=ADDR` | 대상 + 그 대상이 **의존하는** 리소스만. 예외 상황 전용 | S3 |
| | `-replace=ADDR` | 강제 교체 계획(`taint` 대체) | S3 |
| | `-destroy` | 파괴 계획 | S3 |
| | `-detailed-exitcode` | 0 변경 없음 / 1 오류 / 2 변경 있음 | 전체 |
| | `-generate-config-out=FILE` | import 블록 대상의 리소스 코드 생성(파일이 이미 있으면 오류) | S1 |
| apply | `apply FILE` | 저장된 plan을 **프롬프트 없이** 그대로 적용 | S3 |
| | `-refresh-only` | 실제 값을 state에만 기록(`terraform refresh`는 deprecated) | S2 |
| | `-auto-approve`, `-parallelism=n`(기본 10), `-lock-timeout=30s`, `-input=false` | 자동화 옵션 | |
| destroy | `-target=ADDR` | 일부만 파괴 | S3 |
| | `plan -destroy -out` → `apply FILE` | 파괴 계획을 검토한 뒤 적용 | S3 |

> 대괄호가 들어간 주소(`'aws_s3_object.report[0]'`, `'aws_s3_bucket.data["raw"]'`)는 셸 글롭이 먹지 않도록 따옴표로 감쌉니다.

## 2. import (S1)

- 1.5부터 `import { to = ..., id = ... }` 블록을 쓸 수 있고, 1.6부터는 `id`에 변수 같은 표현식을 넣을 수 있습니다. `for_each`는 1.7부터라 1.6에서는 쓸 수 없습니다.
- 흐름: import 블록 작성 → `plan -generate-config-out=generated.tf` → `validate`로 생성 코드 정리 → apply(`N imported, 0 added`) → import 블록 삭제(남겨도 no-op).
- 생성 코드를 정리하는 원칙:
  - 충돌하는 인자 쌍(예: `ipv6_address_count`와 `ipv6_addresses`)이 함께 생성되면 오류에 나온 한쪽을 지웁니다.
  - 하드코딩된 ID는 참조로 바꿉니다(`[aws_security_group.legacy.id]`). 의존성 그래프가 생깁니다.
  - **ForceNew 인자(`ami`, `subnet_id` 등)는 실제 값 그대로 둡니다.** 값을 바꾸면 import 직후 replace가 계획됩니다.
- CLI `terraform import`는 리소스 블록을 먼저 써야 하고 plan 미리보기가 없습니다. 리뷰할 수 있는 import 블록 방식이 낫습니다.
- 성공 판정: 리소스 ID가 그대로인지 봅니다. ID가 바뀌었다면 교체된 것입니다.

## 3. 드리프트 (S2)

```
plan -refresh-only   → 무엇이 바뀌었나 (인프라·state 무변경)
apply -refresh-only  → 실제 값을 state에 수용
설정 수정            → 승인된 변경은 코드에 반영
apply                → 승인되지 않은 변경은 코드 기준으로 원복
```

- state만 갱신해도 **설정은 그대로**입니다. 그래서 다음 일반 plan은 승인된 변경까지 되돌리려 합니다. 승인된 변경은 반드시 코드에 반영하세요.
- 인라인 `ingress`/`egress`는 SG 규칙 전체를 authoritative하게 관리합니다. 코드에 없는 규칙(무단 추가된 22/tcp)은 apply 때 지워집니다. 같은 SG에 `aws_vpc_security_group_ingress_rule`을 섞으면 서로 덮어씁니다.
- 밖에서 삭제된 리소스는 refresh 뒤 state에서 빠지고, 다음 apply에서 다시 생성됩니다.

## 4. count vs for_each (S3, S4)

- `count`는 **인덱스**로 주소를 매깁니다. `["daily","weekly","monthly"]` → `["weekly","monthly"]`로 바꾸면 `[0]`·`[1]`은 replace(key가 ForceNew), `[2]`는 destroy됩니다. 원소 하나를 뺐는데 전부 흔들립니다.
- `for_each`는 **키**로 주소를 매기므로 원소를 추가·삭제해도 다른 인스턴스에 영향이 없습니다. 컬렉션 리소스는 `for_each`를 기본으로 씁니다.

## 5. state 리팩터링 (S4)

| 목적 | 설정 방식 | CLI 방식 | 비고 |
|---|---|---|---|
| 주소 변경 | `moved { from, to }` | `terraform state mv` | moved는 plan에 `has moved to`로 미리 보이고 코드로 남아 모든 workspace·모듈 사용자에게 적용됩니다 |
| 관리 중단(리소스 유지) | `removed { lifecycle { destroy = false } }` **(1.7+)** | 블록 삭제 + `terraform state rm` | 1.6에서는 CLI만 가능. 블록만 지우면 다음 apply에서 **파괴**됩니다 |
| 조회 | | `state list`, `state show ADDR`, `show -json \| jq` | `state list -id=<id>`로 ID 역조회 |
| 원격 state 직접 조작 | | `state pull` / `state push` | serial 검사. `-force`는 위험 |

- `moved` 블록은 바로 지우지 말고 한동안 남겨 두세요. 예전 주소를 쓰는 state가 남아 있을 수 있습니다.
- 관리 리소스 수 세기: `terraform show -json | jq '[.values.root_module.resources[] | select(.mode=="managed")] | length'`

## 6. 1.6 버전 함정

| 기능 | 도입 버전 | 1.6 대안 |
|---|---|---|
| `import` 블록 | 1.5 | 사용 가능 |
| `import` 블록 `id`에 표현식 | 1.6 | 사용 가능 |
| `import` 블록 `for_each` | 1.7 | 블록을 여러 개 작성 |
| `removed` 블록 | 1.7 | `state rm` |
| `terraform test` | 1.6 | 사용 가능 (02-S1) |

## 7. 자주 틀리는 포인트

- `-target`은 대상이 **의존하는** 리소스는 포함하지만, 대상에 **의존하는** 리소스는 포함하지 않습니다(S3: 버킷 생성 시 random 포함, object 제외).
- 저장된 plan 파일로 apply하면 확인 프롬프트가 나오지 않습니다. 이미 검토했다고 간주하기 때문입니다.
- `-replace`는 내용이 같아도 destroy+create를 합니다(`1 added, 0 changed, 1 destroyed`).
- `refresh`·`taint`는 deprecated입니다. 각각 `apply -refresh-only`, `-replace`를 씁니다.
