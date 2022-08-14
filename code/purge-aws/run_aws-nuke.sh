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
# timeout -s 9 14400 aws-nuke --force --no-dry-run \
    # -c /tmp/aws-nuke.conf \
    # --profile default
timeout -s 9 14400 aws-nuke \
    --force \
    -c /tmp/aws-nuke.conf

echo "aws-nuke run complete"%
