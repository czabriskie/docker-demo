#!/usr/bin/env bash
# Step 1 for every AWS target: put the image in a registry (ECR).
# Usage: ./deploy/push-to-ecr.sh <repo-name> [dockerfile]
set -euo pipefail

REPO=${1:?repo name, e.g. iris-api}
DOCKERFILE=${2:-Dockerfile}
REGION=${AWS_REGION:-us-east-1}
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
REGISTRY="$ACCOUNT.dkr.ecr.$REGION.amazonaws.com"

aws ecr describe-repositories --repository-names "$REPO" --region "$REGION" >/dev/null 2>&1 \
  || aws ecr create-repository --repository-name "$REPO" --region "$REGION" >/dev/null
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REGISTRY"

# Lambda/ECS Fargate default to x86_64; pin it so an M-series Mac build still works.
docker build --platform linux/amd64 --provenance=false -f "$DOCKERFILE" -t "$REGISTRY/$REPO:latest" .
docker push "$REGISTRY/$REPO:latest"
echo "Pushed $REGISTRY/$REPO:latest"
