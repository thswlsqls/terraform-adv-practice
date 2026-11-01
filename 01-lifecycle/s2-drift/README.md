# 01-S2. 드리프트 식별과 조정

- 목표: **1b** plan(-refresh-only) · **1c** apply(-refresh-only) · **1e** drift
- 형태: Lab · 권장 20분 · 비용: 거의 없음

## 상황
야간에 Terraform 밖에서 변경 3건이 일어났습니다. 변경 승인 기록은 다음과 같습니다.

| 변경 | 승인 여부 |
|---|---|
| SG `Owner` 태그 `platform` → `security-team` | 승인됨: 코드에 반영 |
| SG에 `22/tcp 0.0.0.0/0` 추가 | 미승인: 원복 |
| S3 `app/config.json` 삭제 | 미승인: 복구 |

## 준비
```bash
terraform init && terraform apply -auto-approve
./drift.sh
```

## 과제
1. **인프라를 바꾸지 않고** 드리프트만 확인하는 plan을 실행하고, 감지된 변경을 `answers.txt`에 리소스 주소별로 적으세요.
2. **설정은 고치지 않은 채로** 현재 실제 값을 state에만 반영하세요. 이때 어떤 명령을 썼는지도 `answers.txt`에 적으세요.
3. 2를 마친 뒤 일반 `terraform plan`이 무엇을 하려 하는지 설명하세요. 실행하면 어떤 결과가 나올지도 함께 적으세요.
4. 승인 기록에 맞게 설정을 고친 뒤 apply하세요.
5. 최종 `terraform plan`이 `No changes`여야 합니다.

## 채점 기준
```bash
terraform plan -detailed-exitcode; echo $?          # 0
aws ec2 describe-security-groups --group-ids "$(terraform output -raw sg_id)" \
  --query 'SecurityGroups[0].[Tags[?Key==`Owner`].Value|[0], length(IpPermissions[?FromPort==`22`])]' --output text
# → security-team  0
aws s3api head-object --bucket "$(terraform output -raw bucket)" --key app/config.json >/dev/null && echo restored
grep -n 'Owner' main.tf                              # security-team
```

## 정리
`terraform destroy`

## 참고 문서
- https://developer.hashicorp.com/terraform/cli/commands/plan#planning-modes
- https://developer.hashicorp.com/terraform/tutorials/state/resource-drift
