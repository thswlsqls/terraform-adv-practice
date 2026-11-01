# 02-S3 해설

정답 코드는 `solution/main.tf`에 있습니다.

- `csvdecode`는 모든 값을 **문자열**로 돌려줍니다. 그래서 `tonumber(each.value.port)`로 바꾸고, `public == "true"`처럼 문자열로 비교해야 합니다.
- `for_each`의 키를 규칙 이름으로 잡으면 CSV 줄 순서가 바뀌거나 줄이 삭제돼도 다른 규칙의 주소는 그대로입니다. count를 쓰면 인덱스가 밀립니다(01-S3).
- 인라인 `ingress`/`egress` 블록과 `aws_vpc_security_group_*_rule` 리소스를 **같은 규칙 방향에** 섞지 마세요. 서로 덮어써서 영구 diff가 생깁니다. 이 문제는 egress는 인라인(dynamic), ingress는 별도 리소스로 방향을 나눴습니다.
- `merge`는 뒤쪽 인자가 이깁니다. `lookup(map, key, default)`는 키가 없을 때의 기본값을 지정하는 함수입니다. `var.m[key]`는 키가 없으면 오류이고, `try(var.m[key], "t3.micro")`도 같은 결과를 냅니다.
- `optional(type, default)`는 1.3부터 쓸 수 있습니다.

## 9. 변수 우선순위 (뒤로 갈수록 높음)
기본값 → `TF_VAR_*` 환경 변수 → `terraform.tfvars` → `terraform.tfvars.json` → `*.auto.tfvars`(.json, 파일명 사전순) → 명령줄 `-var`/`-var-file`(명령줄에 쓴 순서대로, 나중 것이 우선).
그래서 결과는 qa이고 `lookup` 기본값 `t3.micro`가 나옵니다. `-var-file`을 지우면 prod(`t3.small`), auto.tfvars까지 지우면 stg, 그것까지 지우면 dev입니다.

## 퀴즈 정답 (Terraform 1.6.6에서 검증)
| # | 결과 | # | 결과 |
|---|---|---|---|
| 1 | `7` | 11 | `2` |
| 2 | `5` | 12 | `["a=1","b=2"]` (맵은 키 사전순으로 순회) |
| 3 | `null` | 13 | `{"1"=["a"], "2"=["bb","cc"]}` (`...` 그룹 모드) |
| 4 | 오류 (원소 2개 이상) | 14 | `[1, 2]` |
| 5 | `["10","9","A","b"]` (사전순, 대문자 먼저) | 15 | `"10.20.48.0/20"` |
| 6 | `["a","b"]` | 16 | `"b"` (인덱스가 길이를 넘으면 순환) |
| 7 | `"web-007"` | 17 | `0` |
| 8 | `"a,b,c"` | 18 | `"x"` (빈 문자열은 건너뜀) |
| 9 | `{a=1, b=3, c=4}` | 19 | `6` |
| 10 | `"default"` | 20 | `["a","b"]` |
