#! /bin/bash

# AWS account ID
ACCOUNT_ID=${1-072507290151}

REGION=${2-'us-west-2'}

IMAGE_NAME=${3-'django-app_ec2:latest'}

echo "Build docker image:${IMAGE_NAME}"
AWS_PROFILE='default' docker buildx build --platform=linux/amd64 -t ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${IMAGE_NAME} .

echo "Login into AWS ECR" 
AWS_PROFILE='default' aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

echo "docker push ${IMAGE_NAME} to ECR"
AWS_PROFILE='default' docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${IMAGE_NAME}

