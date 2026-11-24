#!/usr/bin/env bash
# Deploy the container image as a Lambda function with a public Function URL.
# Needs: AWS CLI logged in, and an IAM role ARN with AWSLambdaBasicExecutionRole.
# Usage: LAMBDA_ROLE_ARN=arn:aws:iam::123456789012:role/lambda-basic ./deploy/lambda/deploy.sh
set -euo pipefail
REGION=${AWS_REGION:-us-east-1}
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
IMAGE="$ACCOUNT.dkr.ecr.$REGION.amazonaws.com/iris-lambda:latest"

./deploy/push-to-ecr.sh iris-lambda deploy/lambda/Dockerfile

aws lambda create-function --function-name iris-predictor \
  --package-type Image --code ImageUri="$IMAGE" \
  --role "${LAMBDA_ROLE_ARN:?set LAMBDA_ROLE_ARN}" \
  --memory-size 1024 --timeout 30 --region "$REGION"
aws lambda wait function-active --function-name iris-predictor --region "$REGION"

aws lambda create-function-url-config --function-name iris-predictor \
  --auth-type NONE --region "$REGION"
aws lambda add-permission --function-name iris-predictor \
  --statement-id public-url --action lambda:InvokeFunctionUrl \
  --principal '*' --function-url-auth-type NONE --region "$REGION"

# Later updates are one command:
#   aws lambda update-function-code --function-name iris-predictor --image-uri "$IMAGE"
