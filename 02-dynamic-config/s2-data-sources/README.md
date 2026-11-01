# 02-S2. data source로 하드코딩 제거와 IAM 구성

- 목표: **2b** data source로 provider 조회 (+ 2c, 2d `depends_on`, 2e)
- 형태: Lab · 권장 30분 · 비용: t3.micro 1대

## 상황
`main.tf`는 다른 계정·리전에서 복사해 온 코드라서 AMI, 서브넷, 계정 ID가 하드코딩되어 있고 IAM 정책은 JSON heredoc으로 작성되어 있습니다.
**어느 계정·리전에서 실행해도 동작하도록** 고치세요.

## 과제
1. AMI는 Amazon 소유 최신 AL2023 x86_64를 조회해서 쓰세요.
2. 서브넷은 첫 번째 가용 AZ의 **기본 서브넷**을 조회해서 쓰세요.
3. 계정 ID는 실행 주체에서 조회하고, 버킷 이름 `tfadv-artifacts-<account_id>`를 local로 만드세요.
4. 두 JSON heredoc을 `aws_iam_policy_document`로 바꾸세요. `ListBucket`은 버킷 ARN에만, `GetObject`는 `/*`에만 주세요(최소 권한).
5. 인스턴스가 이 역할을 쓰도록 `aws_iam_role_policy_attachment`와 `aws_iam_instance_profile`을 연결하세요.
6. 출력값을 추가하세요.
   - `deployer_issuer_arn`: 지금 Terraform을 실행하는 주체가 assumed role이면 그 **역할 ARN**
   - `app_subnet`: `{ id, az, cidr }` 객체
7. 앱은 부팅 직후 S3에서 설정을 읽습니다. 그래서 인스턴스는 **정책 attachment가 끝난 뒤에** 만들어져야 합니다. 참조만으로는 이 순서가 보장되지 않으니 명시적으로 지정하세요.

## 채점 기준
```bash
grep -nE 'ami-0|subnet-0|111122223333|"Version"' main.tf    # 출력 없음
terraform apply -auto-approve
aws iam get-role --role-name tfadv-app-role \
  --query 'Role.AssumeRolePolicyDocument.Statement[0].Principal.Service' --output text   # ec2.amazonaws.com
aws ec2 describe-instances --filters Name=tag:Name,Values=tfadv-app Name=instance-state-name,Values=running \
  --query 'Reservations[0].Instances[0].IamInstanceProfile.Arn' --output text           # ...:instance-profile/tfadv-app-profile
terraform output app_subnet                                                              # id/az/cidr 객체
terraform graph | grep -c 'aws_instance.app (expand)" -> "\[root\] aws_iam_role_policy_attachment.read_artifacts'   # 1
```

## 정리
`terraform destroy`

## 참고 문서
- https://developer.hashicorp.com/terraform/language/data-sources
- https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document
- https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_session_context
