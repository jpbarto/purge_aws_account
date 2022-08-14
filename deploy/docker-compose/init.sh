#!/usr/bin/env sh

echo STARTING INIT
echo `date`
aws sts get-caller-identity

/gen_aws-nuke_config_all_rsrc.sh > /tmp/aws-nuke.conf
echo "aws-nuke configuration file follows..."
cat /tmp/aws-nuke.conf
echo "END OF FILE"

sleep 120
echo INIT COMPLETE
