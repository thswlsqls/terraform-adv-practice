# 05-S2 해설

```hcl
# deploy/versions.tf
provider "aws" {
  region = "us-east-1"

  assume_role {
    role_arn     = var.role_arn
    session_name = "tfadv-deploy"
  }

  default_tags {
    tags = { Project = "tf-adv-practice" }
  }
}

variable "role_arn" {
  type = string
}
```

```hcl
# deploy/main.tf
data "aws_caller_identity" "current" {}

data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

output "caller_arn" {
  value = data.aws_caller_identity.current.arn
}

output "issuer_arn" {
  value = data.aws_iam_session_context.current.issuer_arn
}
```

- 1. 자격 증명 탐색 순서(AWS provider 문서 기준)
  1. provider 블록의 인자(`access_key` 등, 비권장)
  2. 환경 변수(`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`, `AWS_PROFILE`)
  3. 공유 credentials/config 파일(`profile`, `shared_config_files` 인자 포함, SSO 프로필 지원)
  4. 컨테이너 자격 증명(ECS task role)
  5. EC2 인스턴스 프로필(IMDS)

  `assume_role`은 위에서 얻은 기본 자격 증명으로 STS AssumeRole을 호출합니다.
- provider 블록 안에서 같은 구성이 만드는 리소스 속성을 참조하면 plan 시점에 값을 알 수 없어서 문제가 됩니다. 그래서 역할 생성(`role/`)과 사용(`deploy/`)을 분리했습니다.
- `aws_iam_session_context`는 assumed-role ARN에서 역할 이름을 뽑아 `iam:GetRole`을 호출합니다. 그래서 `role/`의 정책에 `iam:GetRole`이 들어 있습니다. 이 권한이 없으면 `issuer_arn` 조회가 AccessDenied로 실패합니다.
- AssumeRole은 **루트 사용자 자격 증명으로는 호출할 수 없습니다.** IAM 사용자나 역할(SSO 포함)로 실행하세요.
- 갓 만든 역할은 IAM 전파 지연 때문에 AssumeRole이 몇 초 동안 실패할 수 있습니다. 잠시 기다렸다가 다시 시도하세요.
- 4: 오류는 `api error AccessDenied: User: arn:aws:sts::<acct>:assumed-role/tfadv-deployer/tfadv-deploy is not authorized to perform: s3:CreateBucket on resource: "arn:aws:s3:::tfadv-other-..."` 형태입니다. 주체와 동작, 리소스를 읽고 정책의 Resource 패턴(`tfadv-deploy-*`)과 대조하세요.
- 5: (a) GitHub Actions 같은 CI의 **OIDC → `AssumeRoleWithWebIdentity`**(provider의 `assume_role_with_web_identity` 블록이나 `AWS_ROLE_ARN` + `AWS_WEB_IDENTITY_TOKEN_FILE`) (b) HCP Terraform **dynamic provider credentials**(`TFC_AWS_PROVIDER_AUTH=true`, `TFC_AWS_RUN_ROLE_ARN`). 그 밖에 CI 러너의 인스턴스 프로필이나 Vault AWS secrets engine의 단기 자격 증명도 쓸 수 있습니다.
