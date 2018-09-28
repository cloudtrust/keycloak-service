FROM cloudtrust-baseimage:f27

ARG keycloak_service_git_tag
ARG event_emitter_release=0.1
ARG jaeger_release=1.2.0
ARG keycloak_release=3.4.3.Final
ARG keycloak_bridge_release=1.0
ARG wsfed_release=3.4.3
ARG keycloak_client_mappers_release=1.0
ARG keycloak_export_release=0.3
ARG keycloak_authorization_release=0.3
ARG config_git_tag
ARG config_repo

ARG java8_version=1:1.8.0.181-7.b13.fc27
ARG nginx_version=1.12.1-1.fc27

###
###  Prepare the system stuff
###

RUN dnf update -y && \
    dnf install -y java-1.8.0-openjdk-$java8_version nginx-$nginx_version && \
    dnf clean all

RUN groupadd keycloak && \
    useradd -m -s /sbin/nologin -g keycloak keycloak && \
    install -d -v -m755 /opt/keycloak -o root -g root && \
    install -d -v -m755 /opt/keycloak/archive -o root -g root && \
    groupadd agent && \
    useradd -m -s /sbin/nologin -g agent agent && \
    install -d -v -m755 /opt/agent -o root -g root && \
    install -d -v -m755 /etc/agent -o agent -g agent

WORKDIR /opt/keycloak/archive
RUN wget ${keycloak_release} -O keycloak_release.tar.gz && \
    mkdir keycloak_release && \
    tar -xzf keycloak_release.tar.gz -C keycloak_release --strip-components 1 && \
    mv -v keycloak_release keycloak && \
    mv keycloak /opt/keycloak/ && \
    chmod 775 -R /opt/keycloak/ && \
    chown -R root:keycloak /opt/keycloak/

WORKDIR /cloudtrust
RUN git clone git@github.com:cloudtrust/keycloak-service.git && \
    git clone ${config_repo} ./config 

WORKDIR /cloudtrust/keycloak-service
RUN git checkout ${keycloak_service_git_tag}

##
##  System config
##

WORKDIR /cloudtrust/keycloak-service
RUN install -v -m0644 deploy/etc/security/limits.d/* /etc/security/limits.d/ && \
    install -v -m0644 deploy/etc/security/limits.d/01-nginx.conf /etc/security/limits.d/01-nginx.conf && \
    install -v -m0644 deploy/etc/monit.d/* /etc/monit.d/ && \
    install -v -m0644 -D deploy/etc/nginx/conf.d/* /etc/nginx/conf.d/ && \
    install -v -m0644 deploy/etc/nginx/nginx.conf /etc/nginx/nginx.conf && \
    install -v -m0644 deploy/etc/nginx/mime.types /etc/nginx/mime.types && \
    install -v -o root -g root -m 644 -d /etc/systemd/system/nginx.service.d && \
    install -v -o root -g root -m 644 deploy/etc/systemd/system/nginx.service.d/limit.conf /etc/systemd/system/nginx.service.d/limit.conf

##
##  Keycloak Install
##

WORKDIR /cloudtrust/keycloak-service
RUN install -d -v -m755 /opt/keycloak/realmsdump -o keycloak -g keycloak && \
    install -d -v -m755 /opt/keycloak/keycloak/standalone/log -o keycloak -g keycloak && \
    install -d -v -m755 /opt/keycloak/keycloak/standalone/tmp -o keycloak -g keycloak && \
    install -d -v -m755 /opt/keycloak/keycloak/standalone/data -o keycloak -g keycloak && \
    install -d -v -m755 /opt/keycloak/keycloak/standalone/configuration -o keycloak -g keycloak && \
    install -d -v -m0755 /etc/keycloak && \
    install -d -v -m0744 /run/keycloak && \
    install -v -m0755 deploy/etc/keycloak/* /etc/keycloak && \
    install -v -m0755 -o keycloak -g keycloak deploy/opt/keycloak/keycloak/modules/layers.conf /opt/keycloak/keycloak/modules/layers.conf && \
    install -v -m0755 -o keycloak -g keycloak -D deploy/opt/keycloak/keycloak/standalone/bin/standalone.conf /opt/keycloak/keycloak/bin && \
    install -v -m0755 -o keycloak -g keycloak -D deploy/opt/keycloak/keycloak/standalone/configuration/standalone.xml /opt/keycloak/keycloak/standalone/configuration && \
    install -v -o root -g root -m 644 -d /etc/systemd/system/keycloak.service.d && \
    install -v -o root -g root -m 644 deploy/etc/systemd/system/keycloak.service.d/limit.conf /etc/systemd/system/keycloak.service.d/limit.conf && \
    install -v -o root -g root -m 644 deploy/etc/systemd/system/keycloak.service /etc/systemd/system/keycloak.service && \
    install -v -m0755 -o keycloak -g keycloak /opt/keycloak/keycloak/docs/contrib/scripts/systemd/launch.sh /opt/keycloak/keycloak/bin/

##
##  Postgresql support
##

WORKDIR /cloudtrust/keycloak-service
RUN install -d -v -m755 /opt/keycloak/keycloak/modules/system/layers/keycloak/org/postgresql/main/ -o keycloak -g keycloak && \
    install -v -m0775 -o keycloak -g keycloak deploy/opt/keycloak/keycloak/modules/system/layers/keycloak/org/postgresql/main/* /opt/keycloak/keycloak/modules/system/layers/keycloak/org/postgresql/main/

##
##  Keycloak Client Mappers
##

WORKDIR /cloudtrust
RUN wget ${keycloak_client_mappers_release} -O keycloak_client-mappers.tar.gz && \
    mkdir keycloak_client-mappers && \
    tar -xzf keycloak_client-mappers.tar.gz -C keycloak_client-mappers --strip-components 1

WORKDIR /cloudtrust/keycloak_client-mappers
RUN install -d -v -m755 /opt/keycloak/keycloak/modules/system/layers/client-mappers/ -o keycloak -g keycloak && \
    install -d -v -m755 /opt/keycloak/keycloak/modules/system/layers/client-mappers/io/cloudtrust/keycloak-client-mappers/main/ -o keycloak -g keycloak && \
    install -v -m0755 -o keycloak -g keycloak io/cloudtrust/keycloak-client-mappers/main/* /opt/keycloak/keycloak/modules/system/layers/client-mappers/io/cloudtrust/keycloak-client-mappers/main/

##
##  Keycloak Export
##

WORKDIR /cloudtrust
RUN wget ${keycloak_export_release} -O keycloak_export.tar.gz && \
    mkdir keycloak_export && \
    tar -xzf keycloak_export.tar.gz -C keycloak_export --strip-components 1

WORKDIR /cloudtrust/keycloak_export
RUN install -d -v -m755 /opt/keycloak/keycloak/modules/system/layers/export/ -o keycloak -g keycloak && \
    install -d -v -m755 /opt/keycloak/keycloak/modules/system/layers/export/io/cloudtrust/keycloak-export/main/ -o keycloak -g keycloak && \
    install -v -m0755 -o keycloak -g keycloak io/cloudtrust/keycloak-export/main/* /opt/keycloak/keycloak/modules/system/layers/export/io/cloudtrust/keycloak-export/main/

##
##  Authorization
##

WORKDIR /cloudtrust
RUN wget ${keycloak_authorization_release} -O authorization.tar.gz && \
    mkdir authorization && \
    tar -xzf authorization.tar.gz -C authorization --strip-components 1

WORKDIR /cloudtrust/authorization
RUN install -d -v -m755 /opt/keycloak/keycloak/modules/system/layers/authorization -o keycloak -g keycloak && \
    install -d -v -m755 /opt/keycloak/keycloak/modules/system/layers/authorization/io/cloudtrust/keycloak-authorization/main/ -o keycloak -g keycloak && \
    install -v -m0755 -o keycloak -g keycloak io/cloudtrust/keycloak-authorization/main/* /opt/keycloak/keycloak/modules/system/layers/authorization/io/cloudtrust/keycloak-authorization/main

##
##  WS-Fed support
##

WORKDIR /cloudtrust
RUN wget ${wsfed_release} -O wsfed.tar.gz && \
    mkdir wsfed && \
    tar -xzf wsfed.tar.gz -C wsfed --strip-components 1

WORKDIR /cloudtrust/wsfed
RUN install -d -v -m755 /opt/keycloak/keycloak/modules/system/layers/wsfed -o keycloak -g keycloak && \
    install -d -v -m755 /opt/keycloak/keycloak/modules/system/layers/wsfed/com/quest/keycloak-wsfed/main/ -o keycloak -g keycloak && \
    install -v -m0755 -o keycloak -g keycloak com/quest/keycloak-wsfed/main/* /opt/keycloak/keycloak/modules/system/layers/wsfed/com/quest/keycloak-wsfed/main

##
##  Sentry support
##

WORKDIR /cloudtrust/keycloak-service
RUN install -d -v -m755 /opt/keycloak/keycloak/modules/system/layers/sentry -o keycloak -g keycloak && \
    install -d -v -m755 /opt/keycloak/keycloak/modules/system/layers/sentry/io/sentry/main/ -o keycloak -g keycloak && \
    install -d -v -m755 /opt/keycloak/keycloak/modules/system/layers/sentry/io/sentry/log4j/main/ -o keycloak -g keycloak && \
    install -v -m0755 -o keycloak -g keycloak deploy/opt/keycloak/keycloak/modules/system/layers/sentry/io/sentry/main/* /opt/keycloak/keycloak/modules/system/layers/sentry/io/sentry/main/ && \
    install -v -m0755 -o keycloak -g keycloak deploy/opt/keycloak/keycloak/modules/system/layers/sentry/io/sentry/log4j/main/* /opt/keycloak/keycloak/modules/system/layers/sentry/io/sentry/log4j/main/

##
##  JAEGER AGENT
##

WORKDIR /cloudtrust
RUN wget ${jaeger_release} -O jaeger.tar.gz && \
    mkdir jaeger && \
    tar -xzf jaeger.tar.gz -C jaeger --strip-components 1 && \
    install -v -m0755 jaeger/agent-linux /opt/agent/agent && \
    rm jaeger.tar.gz && \
    rm -rf jaeger/

WORKDIR /cloudtrust/keycloak-service
RUN install -v -o agent -g agent -m 644 deploy/etc/systemd/system/agent.service /etc/systemd/system/agent.service && \
    install -d -v -o root -g root -m 644 /etc/systemd/system/agent.service.d && \
    install -v -o root -g root -m 644 deploy/etc/systemd/system/agent.service.d/limit.conf /etc/systemd/system/agent.service.d/limit.conf

##
##  EVENT EMITTER
##

WORKDIR /cloudtrust
RUN wget ${event_emitter_release} -O event-emitter.tar.gz && \
    mkdir event-emitter && \
    tar -xzf event-emitter.tar.gz -C event-emitter --strip-components 1 && \
    rm -f event-emitter.tar.gz

WORKDIR /cloudtrust/event-emitter
RUN install -d -v -m755 -o keycloak -g keycloak /opt/keycloak/keycloak/modules/system/layers/eventemitter/ && \
	install -d -v -m755 -o keycloak -g keycloak /opt/keycloak/keycloak/modules/system/layers/eventemitter/io/cloudtrust/keycloak/eventemitter/main/ && \
    install -v -m0755 -o keycloak -g keycloak io/cloudtrust/keycloak/eventemitter/main/* /opt/keycloak/keycloak/modules/system/layers/eventemitter/io/cloudtrust/keycloak/eventemitter/main/ && \
    install -d -v -m755 -o keycloak -g keycloak /opt/keycloak/keycloak/modules/system/layers/eventemitter/org/apache/commons/collections4/main && \
    install -v -m0755 -o keycloak -g keycloak org/apache/commons/collections4/main/* /opt/keycloak/keycloak/modules/system/layers/eventemitter/org/apache/commons/collections4/main && \
    install -d -v -m755 -o keycloak -g keycloak /opt/keycloak/keycloak/modules/system/layers/eventemitter/com/google/guava/main && \
    install -v -m0755 -o keycloak -g keycloak com/google/guava/main/* /opt/keycloak/keycloak/modules/system/layers/eventemitter/com/google/guava/main/

##
##  KEYCLOAK_BRIDGE
##

WORKDIR /cloudtrust
RUN wget ${keycloak_bridge_release} -O keycloak-bridge.tar.gz && \
    mkdir "keycloak-bridge" && \
    tar -xzf "keycloak-bridge.tar.gz" -C "keycloak-bridge" --strip-components 1 && \
    rm -f keycloak-bridge.tar.gz

WORKDIR /cloudtrust/keycloak-bridge
RUN install -d -v -o keycloak -g keycloak /opt/keycloak-bridge && \ 
    install -v -o keycloak -g keycloak keycloak_bridge /opt/keycloak-bridge

##
##  CONFIG
##

WORKDIR /cloudtrust/config
RUN git checkout ${config_git_tag}

WORKDIR /cloudtrust/config
RUN install -v -m0755 -o keycloak -g keycloak deploy/opt/keycloak/keycloak/standalone/configuration/keycloak-add-user.json /opt/keycloak/keycloak/standalone/configuration/keycloak-add-user.json && \
    install -v -m0644 -o keycloak -g keycloak deploy/opt/keycloak/keycloak/standalone/configuration/standalone.xml /opt/keycloak/keycloak/standalone/configuration/standalone.xml && \
    install -d -v -o keycloak -g keycloak /opt/keycloak-bridge/conf && \
    install -v -o keycloak -g keycloak deploy/opt/keycloak-bridge/conf/keycloak_bridge.yml /opt/keycloak-bridge/conf/ && \
    install -v -o root -g root deploy/etc/systemd/system/keycloak_bridge.service /etc/systemd/system/ && \
    install -d -v -o root -g root /etc/systemd/system/keycloak_bridge.d && \
    install -v -m0755 -o agent -g agent deploy/etc/jaeger-agent/agent.yml /etc/agent/

##
##  Enable services
##

RUN systemctl enable nginx.service && \
    systemctl enable keycloak.service && \
    systemctl enable monit.service && \
    systemctl enable agent.service && \
    systemctl enable keycloak_bridge.service
