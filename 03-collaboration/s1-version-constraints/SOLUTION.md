# 03-S1 해설 (Terraform 1.6.6에서 재현 확인)

| 순서 | 오류 | 원인 | 조치 |
|---|---|---|---|
| 0 | (tfenv 사용 시) `terraform version` → 1.7.5 | 디렉터리의 디코이 `.terraform-version` | 1.6.6으로 교정(과제 4). 교정하지 않으면 1.7.5가 `>= 1.7.0`을 만족해 1행 오류가 숨겨짐 |
| 1 | `Unsupported Terraform Core version` | `required_version = ">= 1.7.0"` | `"~> 1.6.0"` (>= 1.6.0, < 1.7.0) |
| 2 | `locked provider ... random 3.1.0 does not match configured version constraint 3.1.0, >= 3.5.0` | 루트 `3.1.0` 고정 + 모듈 `>= 3.5.0`. 제약은 **모든 모듈의 교집합**으로 계산됩니다 | 루트를 `~> 3.5`로. 그래도 같은 오류(이번엔 `>= 3.5.0, ~> 3.5`)가 남는데, lock이 3.1.0이기 때문입니다 |
| 3 | 위 오류와 **같은 init 출력에서** `Installed hashicorp/aws v4.67.0`, 오류 아님 | aws에 제약이 없어서 lock 버전 4.67.0을 그대로 재사용 | `version = "~> 5.40"` 추가. 이후에는 aws도 `locked provider ... aws 4.67.0 does not match` |
| 4 | 위 lock 불일치 오류들 | lock 파일이 새 제약 밖 | `terraform init -upgrade` 한 번으로 random과 aws 모두 해결 |

```bash
terraform init -upgrade                                           # 제약 안의 최신 버전 선택 + lock 갱신
terraform providers lock -platform=linux_amd64 -platform=darwin_arm64
echo 1.6.6 > .terraform-version                                   # 디렉터리의 1.7.5를 교정 (tfenv는 가장 가까운 상위 파일을 읽음)
```

- 3은 오류가 나지 않는 함정입니다. 제약이 없으면 lock 파일이 사실상 버전을 결정합니다.
- lock 파일은 **커밋**합니다. lock 파일은 **provider만** 기록하고, 모듈 버전은 기록하지 않습니다. 모듈은 `version` 제약과 `init` 시점에 결정됩니다.
- 모듈 업그레이드는 `module` 블록의 `version`을 고친 뒤 `terraform init -upgrade`로 합니다. 제약을 바꾸지 않은 `-upgrade`는 이미 만족하는 고정 버전을 바꾸지 않습니다. 그리고 `required_version`을 바꾼다고 모듈 버전이 바뀌지는 않습니다.
- `~> 5.40`은 `>= 5.40, < 6.0`이고, `~> 5.40.0`은 `>= 5.40.0, < 5.41.0`입니다.
- `providers lock`은 지정한 플랫폼의 `h1:` 해시를 추가합니다. `zh:` 해시는 레지스트리가 공개한 zip 해시입니다.
