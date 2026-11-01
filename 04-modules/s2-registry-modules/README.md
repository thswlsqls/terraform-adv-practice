# 04-S2. 레지스트리 모듈 사용과 모듈 출력 연결

- 목표: **4b** 구성에서 모듈 사용 (source, version, 입력·출력, 메타 인자)
- 형태: Lab · 권장 25분 · 비용: 거의 없음 (S3)

## 상황
버킷을 직접 만들지 말고 공개 레지스트리 모듈 `terraform-aws-modules/s3-bucket/aws`를 쓰라는 플랫폼 표준이 생겼습니다.
시험에서는 Registry 접근이 제한되므로 **모듈 문서(입력·출력 표)를 읽고 바로 쓰는** 연습을 합니다.

## 과제
1. `var.envs`의 env마다 버킷 1개를 모듈로 만드세요.
   - 모듈 버전은 **4.1 이상 5.0 미만**
   - `bucket_prefix = "tfadv-<env>-"`, versioning 활성화, SSE `aws:kms`, `force_destroy = true`
2. 각 버킷에 `README.txt` object를 만드세요. 버킷 이름은 **모듈 출력**에서 가져옵니다.
3. 출력 `buckets`는 `{ dev = <arn>, stg = <arn> }` 형태로 만드세요.
4. `.terraform/modules/modules.json`에서 실제 설치된 모듈 버전을 확인해 `answers.txt`에 적으세요.
5. 아래 질문에 답하세요.
   - 모듈 블록을 추가한 직후 plan이 `Module not installed` 오류를 냅니다. 무엇을 해야 하나요?
   - `source = "git::https://example.com/vpc.git"`에 `version = "1.2.0"`을 붙이면 어떻게 되나요? Git 소스는 버전을 어떻게 고정하나요?
   - HCP Terraform 비공개 레지스트리 모듈의 source 주소 형식은 무엇인가요?

## 채점 기준
```bash
terraform apply -auto-approve
terraform state list | grep -cE 'module.artifacts\["(dev|stg)"\].aws_s3_bucket.this\[0\]$'   # 2
for b in $(terraform output -json buckets | jq -r '.[]' | sed 's/.*://'); do
  aws s3api get-bucket-versioning --bucket "$b" --query Status --output text      # Enabled
  aws s3api head-object --bucket "$b" --key README.txt >/dev/null && echo "$b readme"
done
jq -r '.Modules[] | select(.Key | startswith("artifacts")) | .Version' .terraform/modules/modules.json   # 4.x
```

## 정리
`terraform destroy`

## 참고 문서
- https://developer.hashicorp.com/terraform/language/modules/sources
- https://developer.hashicorp.com/terraform/language/modules/syntax
- https://registry.terraform.io/modules/terraform-aws-modules/s3-bucket/aws/latest
