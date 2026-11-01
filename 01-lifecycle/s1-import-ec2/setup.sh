#!/usr/bin/env bash
# 콘솔 수동 생성 상황 재현: 기본 VPC에 SG 1개 + EC2 1대
set -euo pipefail
REGION=us-east-1   # provider var.region 기본값과 일치시킨다

VPC_ID=$(aws ec2 describe-vpcs --region "$REGION" --filters Name=is-default,Values=true \
  --query 'Vpcs[0].VpcId' --output text)
SG_ID=$(aws ec2 create-security-group --region "$REGION" --vpc-id "$VPC_ID" \
  --group-name legacy-web-sg --description "legacy web" \
  --tag-specifications 'ResourceType=security-group,Tags=[{Key=Project,Value=tf-adv-practice}]' \
  --query GroupId --output text)
aws ec2 authorize-security-group-ingress --region "$REGION" --group-id "$SG_ID" \
  --protocol tcp --port 80 --cidr 0.0.0.0/0 >/dev/null

AMI=$(aws ssm get-parameter --region "$REGION" \
  --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 \
  --query Parameter.Value --output text)
INSTANCE_ID=$(aws ec2 run-instances --region "$REGION" --image-id "$AMI" \
  --instance-type t3.micro --security-group-ids "$SG_ID" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=legacy-web},{Key=Project,Value=tf-adv-practice}]' \
  --query 'Instances[0].InstanceId' --output text)

cat > ids.env <<EOF
export TF_VAR_sg_id=$SG_ID
export TF_VAR_instance_id=$INSTANCE_ID
EOF
cat ids.env
