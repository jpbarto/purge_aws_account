#!/usr/bin/env bash

ORIG_DOCKER_CONTEXT=$(docker context show)
LOCAL_DOCKER_CONTEXT=default
ECS_DOCKER_CONTEXT=awscluster

REGION=${AWS_DEFAULT_REGION}
ACCT_NO=$(aws sts get-caller-identity --query 'Account' --output text)
DOCKER_REGISTRY=${ACCT_NO}.dkr.ecr.${REGION}.amazonaws.com
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ACCT_NO}.dkr.ecr.${REGION}.amazonaws.com
# REPO_URI=$(aws ecr create-repository --repository-name s3locust --region ${REGION} --query 'repository.repositoryUri' --output text)
# aws ecr delete-repository --force --repository-name purge-aws

# create any needed repositories
aws ecr create-repository --repository-name purge-aws --region ${REGION}
for service in $(grep 'image: \${DOCKER_REGISTRY}' docker-compose.yaml | sed -e 's/^.*\///')
do
    aws ecr create-repository --repository-name "$service" --region ${REGION}
    docker buildx build --platform linux/amd64 -f ./${service}.dockerfile -t "$DOCKER_REGISTRY/$service" .
    docker buildx build --platform linux/arm64 -f ./${service}.dockerfile -t "$DOCKER_REGISTRY/$service" .
done

# using the local Docker context build and push the images
docker context use $LOCAL_DOCKER_CONTEXT
# docker compose build can't be used here because the container is built on an M1 Macbook pro which produces an ARM container image
# docker compose cannot / will not then tell Fargate to use Graviton to run the image, hence the below builds an X86 image for Fargate
docker compose push

# using the AWS ECS context run the image
docker context use $ECS_DOCKER_CONTEXT
docker compose up

# restore the original Docker context
docker context use $ORIG_DOCKER_CONTEXT