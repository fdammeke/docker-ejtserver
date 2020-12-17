FROM registry.access.redhat.com/ubi8/openjdk-11
LABEL maintainer="Fabian Dammekens <fabian.dammekens@cegeka.com>"

ENV BUILDER_VERSION 1.0 \
  TZ='UTC' \
  PUID='1001' \
  GUID='1001'

LABEL io.k8s.description="EJT License server" \
      io.k8s.display-name="EJT-License-server" \
      io.openshift.expose-services="8140:https" \
      io.openshift.tags="openshift,docker,puppet,puppetserver,image,builder"

USER root

RUN microdnf -y install bash curl tar tzdata \
    && microdnf -y update \
    && microdnf -y clean all

COPY entrypoint.sh /entrypoint.sh

RUN chmod a+x /entrypoint.sh \
  && touch /etc/timezone \
  && chmod g+w /etc/localtime /etc/timezone \
  && chgrp 0 /etc/localtime /etc/timezone

RUN groupadd -f -g 1001 ejt \
  && useradd -o -s /bin/bash -d /data -u 1001 -g ejt -m ejt \
  && mkdir -p /data /opt/ejtserver \
  && chown -R ejt:0 /data /opt/ejtserver \
  && chmod 771 /opt/ejtserver \
  && ln -sf /opt/ejtserver/bin/admin /usr/local/bin/admin \
  && ln -sf /opt/ejtserver/bin/ejtserver /usr/local/bin/ejtserver

USER 1001

EXPOSE 11862
WORKDIR /data
VOLUME [ "/data" ]

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/usr/local/bin/ejtserver", "start-launchd" ]
