# 01-S3 해설

```bash
terraform init -backend=false && terraform validate            # 1
terraform init && terraform init -upgrade                      # 2 (-upgrade: lock 무시, 제약 내 최신 + lock 갱신)
terraform apply -target=aws_s3_bucket.logs                     # 3 의존 대상 random_integer도 함께 생성
terraform plan -out=tfplan                                     # 4
terraform show -json tfplan | jq '[.resource_changes[] | select(.change.actions==["create"])] | length'   # 3
terraform apply tfplan                                         # 저장된 plan은 프롬프트 없이 적용
terraform plan -var='reports=["weekly","monthly"]'             # 5
terraform apply -replace='aws_s3_object.report[0]'             # 6
terraform destroy -target='aws_s3_object.report[1]'            # 7
terraform plan -destroy -out=destroy.tfplan && terraform apply destroy.tfplan
```

- 3: `-target`은 대상이 의존하는 리소스까지 포함합니다. Terraform은 `Warning: Resource targeting is in effect` … "The -target option is not for routine use" 경고를 출력합니다. 장애 복구 같은 예외 상황에서만 쓰세요.
- 5: count는 인덱스로 주소를 매깁니다. `[0]`은 key와 content가 `weekly`로, `[1]`은 `monthly`로 **바뀌고**(key 변경이라 replace), `[2]`는 destroy됩니다. 값 하나를 뺐을 뿐인데 전부 흔들립니다. 그래서 컬렉션에는 `for_each`를 씁니다(01-S4).
- 6: `taint`는 deprecated입니다. `-replace`는 plan에서 교체를 미리 보여 줍니다.
- `-target` 주소에 대괄호가 있으면 셸 글롭 문제가 생기니 따옴표로 감싸세요.
- 그 밖의 옵션(객관식 대비): `-refresh=false`, `-parallelism=n`(기본 10), `-lock-timeout=30s`, `-input=false`, `-compact-warnings`, `apply -auto-approve`, `plan -detailed-exitcode`(0 변경 없음 / 1 오류 / 2 변경 있음).
