#!/bin/sh

set -e

echo "Configuring environment to nuke AWS account"
env

echo "generating aws-nuke configuration file..."
/gen_aws-nuke_config_all_rsrc.sh > /tmp/aws-nuke.conf

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
