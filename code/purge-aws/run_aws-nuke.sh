#!/bin/sh

set -e

echo "Configuring environment to nuke AWS account"
env

echo "Copying AWS Nuke configuration file ${AWS_NUKE_CONFIG_KEY} from S3 bucket ${AWS_NUKE_CONFIG_BUCKET}"
aws s3 cp s3://${AWS_NUKE_CONFIG_BUCKET}/${AWS_NUKE_CONFIG_KEY} /tmp/aws-nuke.conf

echo "aws-nuke configuration file follows..."
cat /tmp/aws-nuke.conf
echo "END OF FILE"

echo "Running aws-nuke..."
if [ $AWS_NUKE_DELETE = "DELETE" ]; then
    echo AWS_NUKE_DELETE environment variable is set to "DELETE", all resources will be deleted...
    timeout -s 9 14400 aws-nuke run \
        --force --no-dry-run \
        --no-alias-check \
        -c /tmp/aws-nuke.conf
else
    echo AWS_NUKE_DELETE environment variable not set to "DELETE", scanning mode only...
    timeout -s 9 14400 aws-nuke run \
        --force \
        --no-alias-check \
        -c /tmp/aws-nuke.conf
fi

echo "aws-nuke run complete"%
