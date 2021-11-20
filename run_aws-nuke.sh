#!/bin/sh

set -e

echo "Configuring environment to nuke AWS account"
env

# check if an environment variable is specified, use it to create the nuke config
if [ -z ${NUKE_CONF_S3_URI} ]; then
    # no URI specified, provide a default
    # cp /default-aws-nuke.conf /tmp/aws-nuke.conf
    # /gen_aws-nuke_config_ec2_rsrc.sh > /tmp/aws-nuke.conf
    /gen_aws-nuke_config_all_rsrc.sh > /tmp/aws-nuke.conf

    # update the configuration file for the current environment
    # update the targeted account number
    sed -i.bak -e 's/TARGET-AWS-ACCOUNT-NUMBER/'"$TARGET_AWS_ACCOUNT_NUMBER"'/g' /tmp/aws-nuke.conf
    sed -i.bak -e 's,HHG-ECS-CLUSTER,'"$HHG_ECS_CLUSTER"',g' /tmp/aws-nuke.conf
    sed -i.bak -e 's,HHG-LOG-GROUP,'"$HHG_LOG_GROUP"',g' /tmp/aws-nuke.conf
    sed -i.bak -e 's/HHG-IAM-ROLE/'"$HHG_IAM_ROLE"'/g' /tmp/aws-nuke.conf
else
    # URI specified, copy it into place
    aws s3 cp ${NUKE_CONF_S3_URI} /tmp/aws-nuke.conf
fi


echo "aws-nuke configuration file follows..."
cat /tmp/aws-nuke.conf
echo "END OF FILE"

echo "Running aws-nuke..."
timeout -s 9 7200 aws-nuke --force --no-dry-run \
    -c /tmp/aws-nuke.conf \
    --profile default

echo "aws-nuke run complete"%
