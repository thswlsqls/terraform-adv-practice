# 03-S3 해설

```bash
cd network && terraform init -backend-config=../backend.hcl && terraform apply
cd ../app  && terraform init -backend-config=../backend.hcl
terraform workspace new dev  && terraform apply -var state_bucket=<bucket>
terraform workspace new prod && terraform apply -var state_bucket=<bucket>
```

```hcl
# app/main.tf (TODO 부분)
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "network/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "dev_app" {   # 5단계: prod에서만 dev workspace state 조회
  count     = terraform.workspace == "prod" ? 1 : 0
  backend   = "s3"
  workspace = "dev"
  config = {
    bucket = var.state_bucket
    key    = "share-app/terraform.tfstate"
    region = "us-east-1"
  }
}

output "instance_id" {
  value = aws_instance.app.id
}

output "dev_instance_id" {
  value = one(data.terraform_remote_state.dev_app[*].outputs.instance_id)
}

data "aws_security_group" "app" {   # 6단계: 태그 조회로 결합도 낮추기
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
  tags   = { Tier = "app" }
}

locals {
  instance_type = { dev = "t3.micro", prod = "t3.small" }[terraform.workspace]
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = local.instance_type
  subnet_id              = data.terraform_remote_state.network.outputs.subnet_ids[0]
  vpc_security_group_ids = [data.aws_security_group.app.id]

  tags = { Name = "app-${terraform.workspace}" }
}
```

- S3 backend의 workspace state는 `<workspace_key_prefix>/<workspace>/<key>`에 저장됩니다(기본 prefix `env:`). default workspace만 `key` 경로 그대로입니다.
- `terraform_remote_state`는 출력값만 노출하지만, 읽으려면 **state 전체를 읽을 권한**이 필요합니다. state에 든 비밀까지 볼 수 있게 되는 셈입니다. 대안은 다음과 같습니다.
  - provider data source(태그 조회), SSM Parameter Store 같은 별도 저장소
  - HCP Terraform의 `tfe_outputs` data source(출력만 읽고, 값은 sensitive로 처리됨)
- 5: 다른 workspace의 state는 `terraform_remote_state`의 `workspace` 인자로 읽습니다. S3 backend라면 `env:/dev/share-app/terraform.tfstate`를 읽게 됩니다. dev에서는 `count = 0`이라 출력이 null이고, null 출력은 state에 저장되지 않습니다.
- CLI workspace는 **같은 코드와 같은 backend**에 state만 나누는 방식입니다. 권한·backend·코드가 환경마다 달라야 하면 디렉터리를 나누거나 HCP Terraform workspace를 쓰세요.
- 존재하지 않는 workspace에서 위 map을 인덱싱하면 오류가 납니다(`default` workspace 포함). 이 동작은 의도한 가드입니다.
