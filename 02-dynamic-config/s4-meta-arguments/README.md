# 02-S4. lifecycle·count 메타 인자로 무중단 운영

- 목표: **2d** 메타 인자 (count, lifecycle) · AWS: LT, ASG, `aws_security_group_rule`
- 형태: Lab · 권장 35분 · 비용: t3.micro 1~2대 (ASG + 선택 bastion)

## 준비
```bash
terraform init && terraform apply -auto-approve
```

## 과제
1. **보안 그룹 교체 무중단화**: `-var sg_description="web tier v2"`로 plan을 실행해 무엇이 일어나는지 확인하세요. description 변경은 SG를 교체합니다. 이어서 새 SG를 **먼저 만들고 나서** 기존 SG를 지우도록 바꾸세요. 그대로 바꾸면 이름 충돌이 나니 함께 해결해야 합니다.
2. **운영 스케일링 보호**: 운영팀이 다음 명령으로 desired capacity를 바꿉니다.
   ```bash
   aws autoscaling set-desired-capacity --auto-scaling-group-name <asg> --desired-capacity 1
   ```
   이후 Terraform이 이 값을 되돌리지 않게 하세요.
3. **실수로 인한 파괴 방지**: 감사 버킷 `audit`은 `terraform destroy`로도 지워지지 않아야 합니다.
4. **조건부 리소스**: `enable_bastion = true`일 때만 bastion 인스턴스 1대를 만드세요. 출력 `bastion_id`는 bastion이 있으면 ID를, 없으면 `null`을 냅니다. 조건 연산자로 인덱싱하지 마세요.
5. **연쇄 교체**: `release` 값이 바뀌면 bastion이 **교체**되어야 합니다. 이 변수를 인스턴스 인자에 직접 쓰는 방식은 교체 조건이 아닙니다.
6. **규칙 추가**: web SG에 `80/tcp 0.0.0.0/0` ingress를 **`aws_security_group_rule`** 리소스로 추가하세요.
7. **롤링 교체**: Launch Template에 새 버전이 생기면 ASG가 인스턴스를 **자동으로 순차 교체**하게 하세요(인스턴스 1대 환경이므로 최소 정상 비율은 0%).

## 채점 기준
```bash
terraform plan -var sg_description="web tier v2"     # SG: "+/- create replacement and then destroy"
terraform apply -var sg_description="web tier v2" -auto-approve   # 오류 없이 완료
aws autoscaling set-desired-capacity --auto-scaling-group-name "$(terraform output -raw asg_name)" --desired-capacity 1
terraform plan -var sg_description="web tier v2" -detailed-exitcode; echo $?   # 0
terraform output -json | jq 'has("bastion_id")'                # false (null 출력은 state에 저장되지 않음)
terraform apply -var sg_description="web tier v2" -var enable_bastion=true -auto-approve
terraform plan  -var sg_description="web tier v2" -var enable_bastion=true -var release=2026.11.0   # "aws_instance.bastion[0] will be replaced due to changes in replace_triggered_by"
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$(terraform output -raw asg_name)" \
  --query 'AutoScalingGroups[0].[DesiredCapacity]' --output text   # 1 (되돌려지지 않음)
aws ec2 describe-security-groups --group-ids "$(terraform state show aws_security_group.web | awk -F'"' '/^    id +=/{print $2}')" \
  --query 'SecurityGroups[0].IpPermissions[?FromPort==`80`].IpRanges[0].CidrIp' --output text   # 0.0.0.0/0
terraform state list | grep -c '^aws_security_group_rule\.'     # 1
terraform state show aws_autoscaling_group.web | grep -A3 'instance_refresh {' | grep strategy   # "Rolling"
terraform destroy -var sg_description="web tier v2"            # prevent_destroy 오류로 중단
```

## 정리
`audit`의 `prevent_destroy`를 지우고 `terraform destroy`를 실행하세요.

## 참고 문서
- https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle
- https://developer.hashicorp.com/terraform/language/resources/terraform-data
