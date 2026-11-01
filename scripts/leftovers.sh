#!/usr/bin/env bash
# 실습 후 남은 리소스 확인. 태그 기준 + 태그 없이도 보이는 이름(tfadv-*) 기준을 함께 본다.
set -euo pipefail
for r in ${@:-us-east-1 us-west-2 eu-west-1}; do
  echo "== tagged resources: $r"
  aws resourcegroupstaggingapi get-resources --region "$r" \
    --tag-filters Key=Project,Values=tf-adv-practice \
    --query 'ResourceTagMappingList[].ResourceARN' --output text
done
echo "== S3 buckets (global)";       aws s3api list-buckets --query "Buckets[?starts_with(Name,'tfadv-') || starts_with(Name,'drift-') || starts_with(Name,'meta-') || starts_with(Name,'sens-')].Name" --output text
echo "== IAM roles";                 aws iam list-roles --query "Roles[?starts_with(RoleName,'tfadv-')].RoleName" --output text
echo "== IAM policies";              aws iam list-policies --scope Local --query "Policies[?starts_with(PolicyName,'tfadv-')].PolicyName" --output text
echo "== IAM instance profiles";     aws iam list-instance-profiles --query "InstanceProfiles[?starts_with(InstanceProfileName,'tfadv-')].InstanceProfileName" --output text
echo "== DynamoDB (us-east-1)";      aws dynamodb list-tables --region us-east-1 --query "TableNames[?starts_with(@,'tfadv-')]" --output text
echo "== ASG (us-east-1, default_tags 미적용)"; aws autoscaling describe-auto-scaling-groups --region us-east-1 --query "AutoScalingGroups[?starts_with(AutoScalingGroupName,'meta-web-')].AutoScalingGroupName" --output text
echo "== running EC2 (us-east-1)";   aws ec2 describe-instances --region us-east-1 --filters Name=instance-state-name,Values=running --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`]|[0].Value]' --output text
