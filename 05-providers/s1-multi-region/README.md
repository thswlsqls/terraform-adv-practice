# 05-S1. provider alias로 두 리전 배포

- 목표: **5b** provider 구성 (alias, 모듈에 provider 전달) (+ 2d `provider` 메타 인자)
- 형태: Lab · 권장 40분 · 비용: 거의 없음 (S3)

## 상황
DR 요구 사항 때문에 `us-east-1`(primary)과 `us-west-2`(dr) 두 리전에 리소스를 둬야 합니다.

## 과제
1. `us-west-2`용 provider 구성을 `dr` alias로 추가하세요. 기본 태그도 같게 맞춥니다.
2. 같은 AMI 이름 필터로 **두 리전 각각에서** AMI를 조회하고, 출력 `ami_ids`를 `{ primary, dr }` 맵으로 만드세요. 두 값이 다른 이유를 적으세요.
3. `us-west-2`에 `tfadv-dr-` 버킷을 만드세요.
4. `modules/replicated-bucket` 모듈을 만드세요.
   - **두 개의 provider 구성**(`aws.src`, `aws.dst`)을 받아 각 리전에 버킷 1개씩 만듭니다.
   - src 버킷의 모든 객체가 dst 버킷으로 **교차 리전 복제(CRR)**되게 하세요. 필요한 versioning과 IAM 역할(`aws_iam_policy_document` 사용)도 모듈이 만듭니다.
   - 모듈 출력은 `buckets = { src, dst }`(버킷 이름)입니다.
   - 루트에서 `module "reports"`(`name = "tfadv-reports"`)를 호출해 primary를 src로, dr을 dst로 연결하고, 루트 출력 `report_buckets`로 모듈 출력을 내보내세요.
5. alias 없는 기본 provider를 지우면 어떤 리소스들이 영향을 받는지 설명하세요.

## 채점 기준
```bash
terraform apply -auto-approve
terraform output -json ami_ids | jq -e '.primary != .dr'
for b in $(terraform output -json report_buckets | jq -r '.src, .dst') $(terraform state show aws_s3_bucket.dr | awk -F'"' '/^ +bucket +=/{print $2}'); do
  echo "$b $(aws s3api get-bucket-location --bucket $b --query LocationConstraint --output text)"
done
# src → None(us-east-1), dst·dr → us-west-2
grep -n 'provider "aws"' modules/replicated-bucket/*.tf   # 출력 없음
SRC=$(terraform output -json report_buckets | jq -r .src); DST=$(terraform output -json report_buckets | jq -r .dst)
aws s3api get-bucket-replication --bucket "$SRC" \
  --query 'ReplicationConfiguration.Rules[0].[Status,Destination.Bucket]' --output text   # Enabled  arn:aws:s3:::<DST>
echo hi | aws s3 cp - "s3://$SRC/probe.txt"
for i in $(seq 1 20); do   # 최대 5분 대기
  s=$(aws s3api head-object --bucket "$DST" --key probe.txt --region us-west-2 --query ReplicationStatus --output text 2>/dev/null) && break; sleep 15
done; echo "$s"            # REPLICA
```

## 정리
`terraform destroy`

## 참고 문서
- https://developer.hashicorp.com/terraform/language/providers/configuration#alias-multiple-provider-configurations
- https://developer.hashicorp.com/terraform/language/modules/develop/providers
- https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_replication_configuration
