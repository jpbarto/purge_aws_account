#!/bin/sh

set -e

echo "Configuring environment to nuke AWS account"
env

# no URI specified, provide a default
# cp /default-aws-nuke.conf /tmp/aws-nuke.conf
# /gen_aws-nuke_config_ec2_rsrc.sh > /tmp/aws-nuke.conf
/gen_aws-nuke_config_all_rsrc.sh > /tmp/aws-nuke.conf

echo "aws-nuke configuration file follows..."
cat /tmp/aws-nuke.conf
echo "END OF FILE"

echo "Running aws-nuke..."
# timeout -s 9 14400 aws-nuke --force --no-dry-run \
#     -c /tmp/aws-nuke.conf \
#     --profile default
    
timeout -s 9 14400 aws-nuke  \ 
    -c /tmp/aws-nuke.conf \
    --profile default

echo "aws-nuke run complete"%
