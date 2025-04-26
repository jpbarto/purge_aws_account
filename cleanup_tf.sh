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
terraform destroy -auto-approve -var-file "$ACCT_NO/vars.tfvar" -state "$ACCT_NO/terraform.state"
