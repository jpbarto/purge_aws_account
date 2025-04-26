#!/bin/sh

set -e

REGION="${AWS_DEFAULT_REGION:-us-east-2}"
ACCT_NO=$(aws sts get-caller-identity --query 'Account' --output text)
NUKE_CONF=$(realpath $1)

echo Wiping AWS account with configuration file $NUKE_CONF

# This script will 
# - use the purge container image hosted on GitHub
# - create an ECS Fargate cluster on AWS,
# - push the container to an ECR repository,
# - create and run a task on the cluster to wipe the account
#
# This script assumes that Docker and Terraform are installed locally.

export AWS_DEFAULT_REGION=${REGION}
cd deploy/terraform

mkdir -p ${ACCT_NO}
cat >${ACCT_NO}/vars.tfvar <<EOF
config_file = "$NUKE_CONF"
EOF

terraform init
terraform apply -auto-approve -var-file $ACCT_NO/vars.tfvar --state-out "$ACCT_NO/terraform.state"

PURGE_CLUSTER=$(terraform output -raw purge_cluster)
TASK_ARN=$(terraform output -raw task_arn)
SUBNET_ID=$(aws ec2 describe-subnets --filters 'Name=availability-zone,Values='$REGION'a' 'Name=default-for-az,Values=true' --query 'Subnets[0].SubnetId' --output text)
aws ecs run-task \
    --task-definition ${TASK_ARN} \
    --region ${REGION} \
    --cluster ${PURGE_CLUSTER} \
    --launch-type FARGATE \
    --network-configuration 'awsvpcConfiguration={subnets=["'$SUBNET_ID'"],assignPublicIp="ENABLED"}' \
    --overrides 'containerOverrides=[{name=purge-aws-purge-task,environment=[{name="AWS_NUKE_DELETE", value="DELETE"}]}]'
