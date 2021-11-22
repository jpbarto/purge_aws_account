#!/bin/sh

set -e

REGION="${AWS_DEFAULT_REGION:-us-east-2}"
ACCT_NO=$(aws sts get-caller-identity --query 'Account' --output text)

# This script will 
# - build a docker container using the Dockerfile, 
# - create an ECS Fargate cluster on AWS,
# - push the container to an ECR repository,
# - create and run a task on the cluster to wipe the account
#
# This script assumes that Docker and Terraform are installed locally.

LOCAL_IMAGE_TAG='local/wipeit:latest'
docker build . -t ${LOCAL_IMAGE_TAG}

export AWS_DEFAULT_REGION=${REGION}
terraform init
terraform apply -auto-approve
ECR_URL=$(terraform output -raw ecr_url)

aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ACCT_NO}.dkr.ecr.${REGION}.amazonaws.com
docker tag ${LOCAL_IMAGE_TAG} "${ECR_URL}:latest"
docker push "${ECR_URL}:latest"

PURGE_CLUSTER=$(terraform output -raw purge_cluster)
TASK_ARN=$(terraform output -raw task_arn)
aws ecs run-task \
    --task-definition ${TASK_ARN} \
    --region ${REGION} \
    --cluster ${PURGE_CLUSTER} \
    --launch-type FARGATE \
    --network-configuration 'awsvpcConfiguration={subnets=["subnet-b56f47ff"],assignPublicIp="ENABLED"}'