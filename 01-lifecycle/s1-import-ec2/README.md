# 01-S1. 콘솔에서 만든 EC2를 코드로 가져오기

- 목표: **1a** init · **1b** plan · **1e** import
- 형태: Lab · 권장 25분 · 비용: t3.micro 1대 (실습 후 destroy)

## 상황
운영팀이 장애 대응 중 콘솔에서 웹 서버(`legacy-web`)와 보안 그룹(`legacy-web-sg`)을 직접 만들었습니다.
이 두 리소스를 **교체 없이** Terraform 관리로 넘겨야 합니다.

## 준비
```bash
./setup.sh          # SG + EC2 생성, ids.env에 ID 기록
source ids.env      # TF_VAR_sg_id, TF_VAR_instance_id export
terraform init
```

## 과제
1. `imports.tf`에 `import` 블록 2개를 작성하세요. 주소는 `aws_security_group.legacy`, `aws_instance.legacy`로 고정하고, `id`에는 변수(`var.sg_id`, `var.instance_id`)를 쓰세요.
2. 리소스 블록을 직접 쓰지 말고 `terraform plan`으로 `generated.tf`를 생성하세요.
3. `generated.tf`가 `terraform validate`를 통과하도록 정리하세요. EC2의 보안 그룹 ID는 하드코딩 대신 `aws_security_group.legacy.id`를 참조해야 합니다.
4. apply 결과가 **`2 imported, 0 added, 0 destroyed`**여야 합니다. in-place 변경은 0~2건을 허용합니다.
5. 두 리소스에 태그 `ManagedBy = "terraform"`을 추가하고 apply하세요.
6. import 블록을 지운 뒤 `terraform plan`을 실행해 `No changes`인지 확인하세요.

## 채점 기준
```bash
terraform state list                       # 정확히 2줄: aws_instance.legacy, aws_security_group.legacy
terraform plan -detailed-exitcode; echo $? # 0
cat *.tf | grep -c '^import'               # 0
grep -n 'vpc_security_group_ids' generated.tf   # aws_security_group.legacy.id 참조
aws ec2 describe-instances --region us-east-1 --instance-ids "$TF_VAR_instance_id" \
  --query "Reservations[0].Instances[0].[InstanceId,Tags[?Key=='ManagedBy'].Value|[0]]" --output text
# → 처음과 같은 인스턴스 ID + terraform (ID가 바뀌었다면 교체된 것이므로 실패)
```

## 정리
`terraform destroy`

## 참고 문서 (시험 중 열람 가능)
- https://developer.hashicorp.com/terraform/language/import
- https://developer.hashicorp.com/terraform/language/import/generating-configuration
