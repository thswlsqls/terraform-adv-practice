#!/usr/bin/env bash
# Terraform 밖에서 일어난 변경 3건을 재현한다
set -euo pipefail
REGION=us-east-1
SG_ID=$(terraform output -raw sg_id)
BUCKET=$(terraform output -raw bucket)

# 1) 보안팀이 소유권 태그를 변경 (승인된 변경)
aws ec2 create-tags --region "$REGION" --resources "$SG_ID" --tags Key=Owner,Value=security-team
# 2) 누군가 SSH를 전체 공개 (승인되지 않은 변경)
aws ec2 authorize-security-group-ingress --region "$REGION" --group-id "$SG_ID" \
  --protocol tcp --port 22 --cidr 0.0.0.0/0 >/dev/null
# 3) 설정 파일 삭제
aws s3 rm "s3://$BUCKET/app/config.json"
echo "drift injected"
