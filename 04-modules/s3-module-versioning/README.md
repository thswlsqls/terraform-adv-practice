# 04-S3. 모듈 리팩터링과 시맨틱 버저닝

- 목표: **4c** 모듈 리팩터링과 모듈 버저닝 (+ 3a)
- 형태: Lab · 권장 35분 · 비용: 거의 없음 (S3) · git 필요

## 상황
여러 팀이 쓰는 사내 모듈 `module-repo`(로컬 git)를 개선해야 합니다. 소비자 구성(`consumer/`)은 태그로 버전을 고정합니다.
**모듈을 업그레이드해도 소비자의 기존 버킷은 교체되면 안 됩니다.**

## 준비
```bash
./setup.sh
cd consumer && terraform init && terraform apply -auto-approve && terraform output -raw bucket_id > ../before.txt
```

## 과제
1. **모듈 v1.1.0**(`module-repo`에서 작업)
   - 리소스 이름을 `aws_s3_bucket.bucket`에서 `aws_s3_bucket.this`로 바꾸세요(모듈 표준 명명).
   - `aws_s3_bucket_versioning.this`를 추가하고 입력 `versioning`(bool, 기본 `true`)으로 켜고 끌 수 있게 하세요.
   - 소비자 쪽에서 아무 조치 없이도 교체가 일어나지 않도록 하세요.
   - 커밋하고 태그를 붙이세요. 이 변경이 왜 MINOR인지 `answers.txt`에 적으세요.
2. 소비자를 `v1.1.0`으로 올리세요. plan 결과가 **moved 1, add 1, destroy 0**이어야 합니다.
3. **모듈 v2.0.0**: 입력 `name`을 `name_prefix`로 바꾸세요. 이 변경은 하위 호환이 깨지는 변경입니다. 태그를 붙이고 소비자를 v2.0.0으로 올리세요.
4. v1.0.0을 쓰던 다른 팀이 v1.1.0을 건너뛰고 바로 v2.0.0으로 올려도 안전하려면, v2.0.0에 무엇이 남아 있어야 하나요?

## 채점 기준
```bash
git -C module-repo tag                       # v1.0.0 v1.1.0 v2.0.0
grep -n 'ref=v2.0.0' consumer/main.tf
cd consumer
terraform plan -detailed-exitcode; echo $?  # 0
diff <(terraform output -raw bucket_id) ../before.txt && echo same-bucket
aws s3api get-bucket-versioning --bucket "$(terraform output -raw bucket_id)" --query Status --output text   # Enabled
```

## 정리
`cd consumer && terraform destroy`

## 참고 문서
- https://developer.hashicorp.com/terraform/language/modules/develop/refactoring
- https://developer.hashicorp.com/terraform/language/modules/sources#selecting-a-revision
- https://developer.hashicorp.com/terraform/language/modules/develop/publish
