FROM ghcr.io/ekristen/aws-nuke:v3.48.2

USER root

RUN apk --no-cache update && \
    apk --no-cache add jq aws-cli && \
    rm -rf /var/cache/apk/*

COPY gen_aws-nuke_config_all_rsrc.sh /gen_aws-nuke_config_all_rsrc.sh
COPY run_aws-nuke.sh /run_aws-nuke.sh
RUN chown aws-nuke /*.sh && chmod 0755 /*.sh 

USER aws-nuke

# configure aws cli
RUN mkdir /home/aws-nuke/.aws
COPY aws-cli-config /home/aws-nuke/.aws/config

ENTRYPOINT [ "/run_aws-nuke.sh" ]
