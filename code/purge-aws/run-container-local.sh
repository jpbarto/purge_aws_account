#!/usr/bin/env bash

set -e

docker build . -t jpbarto/purge-aws
docker run \
    --env AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN} \
    --env AWS_SECURITY_TOKEN=${AWS_SECURITY_TOKEN} \
    --env AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
    --env AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
    --env AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION} \
    jpbarto/purge-aws