#!/usr/bin/env sh

set -e

CONF_FILE=/tmp/aws-nuke_ec2.yml
REGIONS=$(aws ec2 describe-regions --region us-east-1 --query 'Regions[].RegionName' --output text)
TARGET_ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text)
RSRC_TYPES=$(aws-nuke resource-types | tr -d '\r')

cat > $CONF_FILE <<EOF
---
account-blocklist:
  - "012345678901"

feature-flags:
  disable-deletion-protection:
    RDSInstance: true
    EC2Instance: true
    CloudformationStack: true

resource-types:
  targets:
  - EC2Instance
  - AutoScalingGroup
  - EC2SpotFleetRequest

accounts:
  "${TARGET_ACCOUNT}":
    presets:
    - isengard
    - tagged_dnd
    - named_dnd
    - okta

regions:
  - global
EOF

for r in ${REGIONS}
do
    echo "  - $r" >> $CONF_FILE
done

# generate a preset to protect resources with 'Isengard' in the name
cat >>$CONF_FILE <<EOF
presets:
  okta:
    filters:
      IAMSAMLProvider:
      - type: contains
        value: "okta"
  isengard:
    filters:
EOF
for t in ${RSRC_TYPES}:
do
    echo "      $t:" >> $CONF_FILE
    echo '      - type: regex' >>$CONF_FILE
    echo '        value: "[Ii]sengard"' >>$CONF_FILE
done

# generate a preset to protect resources with a DO-NOT-DELETE tag set
cat >>$CONF_FILE <<EOF
  tagged_dnd:
    filters:
EOF
for t in ${RSRC_TYPES}:
do
    echo "      $t:" >> $CONF_FILE
    echo '      - property: "tag:DO-NOT-DELETE"' >>$CONF_FILE
    echo '        type: regex' >>$CONF_FILE
    echo '        value: ".+"' >>$CONF_FILE
done

# generate a preset to protect resources with 'DO-NOT-DELETE' in the name
cat >>$CONF_FILE <<EOF
  named_dnd:
    filters:
EOF
for t in ${RSRC_TYPES}:
do
    echo "      $t:" >>$CONF_FILE
    echo '      - type: regex' >>$CONF_FILE
    echo '        value: "(?i)DO-NOT-DELETE"' >>$CONF_FILE
done

cat $CONF_FILE
