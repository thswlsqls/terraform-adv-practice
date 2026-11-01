# 05-S3. provider 오류 트러블슈팅

- 목표: **5a** 플러그인 기반 아키텍처 · **5d** provider 오류 해결 (+ 3a)
- 형태: Lab + 서술 · 권장 30분 · 비용: 거의 없음 (S3)

## 상황
동료가 "init도 안 된다"며 이 디렉터리를 넘겼습니다. 의도는 다음과 같습니다.
- 기본 리전 `us-east-1`에 `modules/logs` 버킷
- `eu-west-1`에 감사(audit) 버킷
- 모든 리소스에 `Project = "tf-adv-practice"` 태그(누락 시 정리 스크립트가 찾지 못함)

## 과제
1. `init`부터 `apply`까지 성공할 때까지 오류를 **하나씩** 고치세요. 오류마다 `TROUBLESHOOT.md`에 다음을 적습니다.
   - 실행한 명령
   - 오류 제목(Error: ...)
   - 근본 원인
   - 수정 내용
   (오류는 최소 3건입니다. 그중 하나는 메시지가 실제 원인과 다르게 읽힐 수 있습니다.)
2. init 오류를 고친 직후(region 오류를 고치기 전), `plan`의 provider 쪽 디버그 로그만 `provider.log` 파일에 남기세요. Terraform 코어 로그는 남기지 않습니다.
3. `terraform providers` 출력으로 **어느 모듈이 어떤 제약을 요구하는지** 확인하고, 그 결과를 붙여 넣으세요.
4. 아래 질문에 답하세요(5a).
   - provider 바이너리는 디스크 어디에 설치되고, Terraform 코어와 어떻게 통신하나요?
   - 같은 lock 파일로 macOS에서는 init이 되는데 Linux CI에서 `doesn't match any of the checksums` 오류가 납니다. 원인과 해결책은 무엇인가요?
   - 여러 작업 디렉터리에서 provider를 반복해서 다운로드하지 않으려면 무엇을 설정하나요?

## 채점 기준
```bash
terraform init -input=false && terraform validate        # 성공
terraform apply -auto-approve                            # 성공
grep -c 'provider.terraform-provider-aws' provider.log   # 1 이상 (provider 로그 존재)
aws s3api get-bucket-location --bucket "$(terraform state show aws_s3_bucket.audit | awk -F'"' '/^ +bucket +=/{print $2}')" \
  --query LocationConstraint --output text               # eu-west-1
grep -c '^## ' TROUBLESHOOT.md                           # 3 이상
cat *.tf | grep -c 'default_tags'                        # 2 이상 (기본 + eu provider)
```

## 정리
`terraform destroy`

## 참고 문서
- https://developer.hashicorp.com/terraform/internals/debugging
- https://developer.hashicorp.com/terraform/cli/commands/providers
- https://developer.hashicorp.com/terraform/cli/config/config-file#provider-plugin-cache
- https://developer.hashicorp.com/terraform/language/files/dependency-lock#checksum-verification
