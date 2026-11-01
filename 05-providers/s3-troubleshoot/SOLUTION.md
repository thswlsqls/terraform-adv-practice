# 05-S3 해설 (Terraform 1.6.6에서 재현 확인)

| # | 명령 | 오류 | 원인 | 수정 |
|---|---|---|---|---|
| 1 | `init` | `Failed to query available provider packages` … `no available releases match the given constraints ~> 5.0, >= 6.0.0` | 루트 `~> 5.0`과 모듈 `>= 6.0`의 교집합이 비어 있음 | 모듈 제약을 `>= 5.0`으로 완화(재사용 모듈은 **하한만** 거는 것이 관례) |
| 2 | `validate` | `Provider configuration not present` … "it has been removed" | 메시지는 "제거됨"이라고 하지만, 실제로는 `aws.eu` alias를 **선언한 적이 없음** | `provider "aws" { alias = "eu"  region = "eu-west-1" }` 추가(두 provider 모두 `default_tags` 포함) |
| 3 | `plan` | `invalid AWS Region: us-east-9` | `var.region` 기본값 오타 | `us-east-1` |
| (+) | `plan` | `InvalidClientTokenId` / `no valid credential sources found` | 자격 증명 누락이나 만료 | 05-S2 참고 |

```bash
TF_LOG_PROVIDER=DEBUG TF_LOG_PATH=provider.log terraform plan   # 2. provider 로그만
terraform providers                                              # 3. 모듈별 요구 사항 트리
```

- 로그 변수: `TF_LOG`(전체), `TF_LOG_CORE`(코어만), `TF_LOG_PROVIDER`(provider만). 레벨은 `TRACE`/`DEBUG`/`INFO`/`WARN`/`ERROR`/`JSON`이고, `TF_LOG_PATH`를 주면 파일로 남깁니다.
- 크래시가 나면 `crash.log`가 생성됩니다. 이슈를 올릴 때 이 파일을 첨부하세요.
- 4. 답변
  - provider는 `.terraform/providers/<host>/<namespace>/<type>/<version>/<os_arch>/`에 설치되는 **별도 실행 파일**입니다. 코어가 이 플러그인 프로세스를 띄우고 gRPC(plugin protocol)로 통신합니다. 코어는 리소스 API를 모르고 provider가 스키마와 CRUD를 담당합니다.
  - lock 파일에 현재 플랫폼(darwin_arm64)의 `h1:` 해시만 있어서 linux_amd64 패키지를 검증하지 못한 경우입니다. `terraform providers lock -platform=linux_amd64 -platform=darwin_arm64`로 해시를 추가하세요(03-S1).
  - CLI 설정 파일(`~/.terraformrc`)의 `plugin_cache_dir`나 `TF_PLUGIN_CACHE_DIR`를 설정합니다. 폐쇄망에서는 `terraform providers mirror`와 `provider_installation { filesystem_mirror {...} }`를 씁니다.
