#!/bin/sh

set -e

REGION="${AWS_DEFAULT_REGION:-us-east-2}"
ACCT_NO=$(aws sts get-caller-identity --query 'Account' --output text)

# This script will 
# - use the purge container image hosted on GitHub
# - create an ECS Fargate cluster on AWS,
# - push the container to an ECR repository,
# - create and run a task on the cluster to wipe the account
#
# This script assumes that Docker and Terraform are installed locally.

export AWS_DEFAULT_REGION=${REGION}
cd deploy/terraform
terraform init
terraform apply -auto-approve

PURGE_CLUSTER=$(terraform output -raw purge_cluster)
TASK_ARN=$(terraform output -raw task_arn)
SUBNET_ID=$(aws ec2 describe-subnets --filters 'Name=availability-zone,Values='$REGION'a' 'Name=default-for-az,Values=true' --query 'Subnets[0].SubnetId' --output text)
aws ecs run-task \
    --task-definition ${TASK_ARN} \
    --region ${REGION} \
    --cluster ${PURGE_CLUSTER} \
    --launch-type FARGATE \
    --network-configuration 'awsvpcConfiguration={subnets=["'$SUBNET_ID'"],assignPublicIp="ENABLED"}'
