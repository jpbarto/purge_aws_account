#!/usr/bin/env sh

set -e

CONF_FILE=/tmp/aws-nuke_all.yml
REGIONS=$(aws ec2 describe-regions --region us-east-1 --query 'Regions[?RegionOptState!=`DISABLED`].RegionName' --output text)
TARGET_ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text)
# RSRC_TYPES=$(aws-nuke resource-types | cut -d' ' -f1 | tr -d '\r')

cat > $CONF_FILE <<EOF
---
blocklist:
  - "012345678901"

settings:
  EC2Image:
    IncludeDisabled: true
    IncludeDeprecated: true
    DisableDeregistrationProtection: true
  EC2Instance:
    DisableStopProtection: true
    DisableDeletionProtection: true
  RDSInstance:
    DisableDeletionProtection: true
  CloudFormationStack:
    DisableDeletionProtection: true
  DynamoDBTable:
    DisableDeletionProtection: true

accounts:
  "${TARGET_ACCOUNT}":
    presets:
    - defaults
    - organization
    - tagged_dnd
    - named_dnd

regions:
EOF

if [ -z ${TARGET_AWS_REGION} ]; then
    echo "  - global" >> $CONF_FILE
    for r in ${REGIONS}
    do
        echo "  - $r" >> $CONF_FILE
    done
else
    echo "  - ${TARGET_AWS_REGION}" >> $CONF_FILE
fi

# generate a preset to protect resources with 'Isengard' in the name
cat >>$CONF_FILE <<EOF

resource-types:
  excludes:
    - S3Object # Excluded because S3 bucket removal handles removing all S3Objects
    - ServiceCatalogTagOption # Excluded due to https://github.com/rebuy-de/aws-nuke/issues/515
    - ServiceCatalogTagOptionPortfolioAttachment # Excluded due to https://github.com/rebuy-de/aws-nuke/issues/515
    - FMSNotificationChannel # Excluded because it's not available
    - FMSPolicy # Excluded because it's not available
    - MachineLearningMLModel # Excluded due to ML being unavailable
    - MachineLearningDataSource # Excluded due to ML being unavailable
    - MachineLearningBranchPrediction # Excluded due to ML being unavailable
    - MachineLearningEvaluation # Excluded due to ML being unavailable
    - RoboMakerDeploymentJob # Deprecated Service
    - RoboMakerFleet # Deprecated Service
    - RoboMakerRobot # Deprecated Service
    - RoboMakerSimulationJob
    - RoboMakerRobotApplication
    - RoboMakerSimulationApplication
    - OpsWorksApp # Deprecated service
    - OpsWorksInstance # Deprecated service
    - OpsWorksLayer # Deprecated service
    - OpsWorksUserProfile # Deprecated service
    - OpsWorksCMBackup # Deprecated service
    - OpsWorksCMServer # Deprecated service
    - OpsWorksCMServerState # Deprecated service
    - CodeStarProject # Deprecated service
    - CodeStarConnection # Deprecated service
    - CodeStarNotification # Deprecated service
    - Cloud9Environment # Deprecated service
    - CloudSearchDomain # Deprecated service
    - RedshiftServerlessSnapshot # Deprecated service
    - RedshiftServerlessNamespace # Deprecated service
    - RedshiftServerlessWorkgroup # Deprecated service
  includes:
    - EC2Instance
    - RDSDBCluster
    - RDSInstance
    - DynamoDBTable
    - EKSCluster 
    - LambdaFunction 

presets:
  organization:
    filters:
      IAMSAMLProvider:
        - property: ARN
          type: contains
          value: "AWSSSO"
      IAMRole:
        - property: Name
          type: contains
          value: "OrganizationAccountAccessRole"
      IAMRolePolicyAttachment:
        - property: RoleName
          value: "OrganizationAccountAccessRole"

  defaults:
    filters:
      EC2Subnet:
        - property: DefaultVPC
          value: "true"
      EC2DefaultSecurityGroupRule:
        - property: DefaultVPC
          value: "true"
      EC2DHCPOption:
        - property: DefaultVPC
          value: "true"
      EC2VPC:
        - property: IsDefault
          value: "true"
      EC2InternetGateway:
        - property: DefaultVPC
          value: "true"
      EC2InternetGatewayAttachment:
        - property: DefaultVPC
          value: "true"

  tagged_dnd: # prevent deletion of anything tagged with a tag named 'DO-NOT-DELETE'
    filters:
      __global__:
        - property: tag:DO-NOT-DELETE
          type: regex
          value: ".*(?i)DO-NOT-DELETE.*"

  named_dnd: # prevent deletion of anything named 'DO-NOT-DELETE'
    filters:
      __global__:
        - property: Name
          type: regex
          value: ".*(?i)DO-NOT-DELETE.*"
EOF

# # generate a preset to protect resources with a DO-NOT-DELETE tag set
# cat >>$CONF_FILE <<EOF
#   tagged_dnd: # prevent deletion of anything tagged 'DO-NOT-DELETE'
#     filters:
# EOF
# while IFS= read -r t; 
# do
#     echo "      $t:" >> $CONF_FILE
#     echo '      - property: "tag:DO-NOT-DELETE"' >>$CONF_FILE
#     echo '        type: regex' >>$CONF_FILE
#     echo '        value: ".+"' >>$CONF_FILE
# done <<< "${RSRC_TYPES}"

# # generate a preset to protect resources with 'DO-NOT-DELETE' in the name
# cat >>$CONF_FILE <<EOF
#   named_dnd: # prevent deletion of anything named 'DO-NOT-DELETE'
#     filters:
# EOF
# while IFS= read -r t; 
# do
#     echo "      $t:" >>$CONF_FILE
#     echo '      - type: regex' >>$CONF_FILE
#     echo '        value: "(?i)DO-NOT-DELETE"' >>$CONF_FILE
# done <<< "${RSRC_TYPES}"

cat $CONF_FILE
