#!/usr/bin/env bash
# Run the API on ECS Fargate (serverless containers, always-on).
# Needs: subnet + security group (port 8080 open) in your VPC.
# Usage: SUBNET=subnet-abc SG=sg-abc ./deploy/ecs/deploy.sh
set -euo pipefail
REGION=${AWS_REGION:-us-east-1}
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)

./deploy/push-to-ecr.sh iris-api Dockerfile

sed "s/ACCOUNT_ID/$ACCOUNT/g" deploy/ecs/task-definition.json > /tmp/taskdef.json
aws ecs register-task-definition --cli-input-json file:///tmp/taskdef.json --region "$REGION"

aws ecs create-cluster --cluster-name demo --region "$REGION" >/dev/null
aws ecs create-service --cluster demo --service-name iris-api \
  --task-definition iris-api --desired-count 2 --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[${SUBNET:?}],securityGroups=[${SG:?}],assignPublicIp=ENABLED}" \
  --region "$REGION"

# In real customer setups an Application Load Balancer sits in front of the
# service (add --load-balancers ...), and this is usually Terraform/CDK, not CLI.
