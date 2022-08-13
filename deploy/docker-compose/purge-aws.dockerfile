FROM quay.io/rebuy/aws-nuke:latest

USER root

RUN apk --no-cache update && \
    apk --no-cache add jq aws-cli && \
    rm -rf /var/cache/apk/*

COPY init.sh /init.sh
RUN chown aws-nuke /*.sh && chmod 0755 /*.sh 

USER aws-nuke

ENTRYPOINT [ "/init.sh" ]
