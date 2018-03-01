FROM cloudtrust-baseimage:f27

ARG keycloak_service_git_tag
ARG event_emitter_release
ARG jaeger_release 
ARG keycloak_bridge_release
ARG config_git_tag
ARG config_repo

#Get dependencies and put keycloak where we expect it to be
RUN dnf install -y java java-1.8.0-openjdk.x86_64 monit git nginx vim wget && \
    dnf clean all

RUN groupadd keycloak && \
    useradd -m -s /sbin/nologin -g keycloak keycloak && \
    install -d -v -m755 /opt/keycloak -o root -g root && \
    install -d -v -m755 /opt/keycloak/archive -o root -g root && \
    groupadd agent && \
    useradd -m -s /sbin/nologin -g agent agent && \
    install -d -v -m755 /etc/agent/ -o agent -g agent

WORKDIR /opt/keycloak/archive
RUN wget https://downloads.jboss.org/keycloak/3.4.3.Final/keycloak-3.4.3.Final.tar.gz && \
    tar -xzf keycloak-3.4.3.Final.tar.gz && \
    mv -v keycloak-3.4.3.Final keycloak && \
    mv keycloak /opt/keycloak/ && \
    chmod 775 -R /opt/keycloak/ && \
    chown -R root:keycloak /opt/keycloak/

# Get jaeger agent
WORKDIR /cloudtrust
RUN wget ${jaeger_release} -O jaeger.tar.gz && \
    mkdir jaeger && \
    tar -xzf jaeger.tar.gz -C jaeger --strip-components 1 && \
    install -v -m0755 jaeger/agent-linux /etc/agent/agent && \
    rm jaeger.tar.gz && \
    rm -rf jaeger/

WORKDIR /cloudtrust
RUN wget ${event_emitter_release} -O event_emitter.tar.gz && \
    mkdir event_emitter && \
    tar -xzf event_emitter.tar.gz -C event_emitter --strip-components 1 && \
    rm -f event_emitter.tar.gz

WORKDIR /cloudtrust
RUN wget ${keycloak_bridge_release} -O keycloak-bridge.tar.gz && \
    mkdir "keycloak-bridge" && \
    tar -xzf "keycloak-bridge.tar.gz" -C "keycloak-bridge" --strip-components 1 && \
    rm -f keycloak-bridge.tar.gz

WORKDIR /cloudtrust/keycloak-bridge
RUN install -d -v -o root -g root /opt/keycloak-bridge && \ 
    install -v -o root -g root keycloakd /opt/keycloak-bridge

WORKDIR /cloudtrust
RUN git clone git@github.com:cloudtrust/keycloak-service.git && \
    git clone ${config_repo} ./config 

WORKDIR /cloudtrust/keycloak-service
RUN git checkout ${keycloak_service_git_tag}

WORKDIR /cloudtrust/keycloak-service
# Install regular stuff. Systemd, monit, nginx...
RUN install -v -m0644 deploy/etc/security/limits.d/* /etc/security/limits.d/ && \
    install -v -m0644 deploy/etc/security/limits.d/01-nginx.conf /etc/security/limits.d/01-nginx.conf && \
    install -v -m0644 deploy/etc/monit.d/* /etc/monit.d/ && \
    install -v -m0644 -D deploy/etc/nginx/conf.d/* /etc/nginx/conf.d/ && \
    install -v -m0644 deploy/etc/nginx/nginx.conf /etc/nginx/nginx.conf && \
    install -v -m0644 deploy/etc/nginx/mime.types /etc/nginx/mime.types && \
    install -v -o root -g root -m 644 -d /etc/systemd/system/nginx.service.d && \
    install -v -o root -g root -m 644 deploy/etc/systemd/system/nginx.service.d/limit.conf /etc/systemd/system/nginx.service.d/limit.conf

WORKDIR /cloudtrust/keycloak-service
# Install keycloak itself
RUN install -d -v -m755 /opt/keycloak/realmsdump -o keycloak -g keycloak && \
    install -d -v -m755 /opt/keycloak/keycloak/standalone/log -o keycloak -g keycloak && \
    install -d -v -m755 /opt/keycloak/keycloak/standalone/tmp -o keycloak -g keycloak && \
    install -d -v -m755 /opt/keycloak/keycloak/standalone/data -o keycloak -g keycloak && \
    install -d -v -m755 /opt/keycloak/keycloak/standalone/configuration -o keycloak -g keycloak && \
    install -d -v -m0755 /etc/keycloak && \
    install -d -v -m0744 /run/keycloak && \
    install -v -m0755 deploy/etc/keycloak/* /etc/keycloak && \
    install -v -m0755 -o keycloak -g keycloak -D deploy/opt/keycloak/keycloak/standalone/bin/standalone.conf /opt/keycloak/keycloak/bin && \
    install -v -m0755 -o keycloak -g keycloak -D deploy/opt/keycloak/keycloak/standalone/configuration/standalone.xml /opt/keycloak/keycloak/standalone/configuration && \
    install -v -o root -g root -m 644 -d /etc/systemd/system/keycloak.service.d && \
    install -v -o root -g root -m 644 deploy/etc/systemd/system/keycloak.service.d/limit.conf /etc/systemd/system/keycloak.service.d/limit.conf && \
    install -v -o root -g root -m 644 deploy/etc/systemd/system/keycloak.service /etc/systemd/system/keycloak.service && \
    install -v -m0755 -o keycloak -g keycloak /opt/keycloak/keycloak/docs/contrib/scripts/systemd/launch.sh /opt/keycloak/keycloak/bin/

WORKDIR /cloudtrust/keycloak-service
#Install postgresql support
RUN install -v -m0755 -o keycloak -g keycloak deploy/opt/keycloak/keycloak/modules/layers.conf /opt/keycloak/keycloak/modules/layers.conf && \
    install -v -m0775 -o keycloak -g keycloak -d /opt/keycloak/keycloak/modules/system/layers/keycloak/org/postgresql && \
    install -v -m0775 -o keycloak -g keycloak -d /opt/keycloak/keycloak/modules/system/layers/keycloak/org/postgresql/main && \
    install -v -m0775 -o keycloak -g keycloak deploy/opt/keycloak/keycloak/modules/system/layers/keycloak/org/postgresql/main/* /opt/keycloak/keycloak/modules/system/layers/keycloak/org/postgresql/main/

WORKDIR /cloudtrust/keycloak-service
RUN install -d -v -m755 /opt/keycloak/keycloak/modules/system/layers/wsfed -o keycloak -g keycloak && \
    install -d -v -m755 /opt/keycloak/keycloak/modules/system/layers/wsfed/com/quest/keycloak-wsfed/main/ -o keycloak -g keycloak && \
    install -v -m0755 -o keycloak -g keycloak -D deploy/opt/keycloak/keycloak/modules/system/layers/wsfed/com/quest/keycloak-wsfed/main/* /opt/keycloak/keycloak/modules/system/layers/wsfed/com/quest/keycloak-wsfed/main

WORKDIR /cloudtrust/keycloak-service
RUN install -d -v -m755 /opt/keycloak/keycloak/modules/system/layers/sentry -o keycloak -g keycloak && \
    install -d -v -m755 /opt/keycloak/keycloak/modules/system/layers/sentry/io/sentry/main/ -o keycloak -g keycloak && \
    install -d -v -m755 /opt/keycloak/keycloak/modules/system/layers/sentry/io/sentry/log4j/main/ -o keycloak -g keycloak && \
    install -v -m0755 -o keycloak -g keycloak -D deploy/opt/keycloak/keycloak/modules/system/layers/sentry/io/sentry/main/* /opt/keycloak/keycloak/modules/system/layers/sentry/io/sentry/main/ && \
    install -v -m0755 -o keycloak -g keycloak -D deploy/opt/keycloak/keycloak/modules/system/layers/sentry/io/sentry/log4j/main/* /opt/keycloak/keycloak/modules/system/layers/sentry/io/sentry/log4j/main/

WORKDIR /cloudtrust/keycloak-service
# Jaeger agent
RUN install -v -o agent -g agent -m 644 deploy/etc/systemd/system/agent.service /etc/systemd/system/agent.service && \
    install -d -v -o root -g root -m 644 /etc/systemd/system/agent.service.d && \
    install -v -o root -g root -m 644 deploy/etc/systemd/system/agent.service.d/limit.conf /etc/systemd/system/agent.service.d/limit.conf

WORKDIR /cloudtrust/event-emitter
# Event emitter and its dependencies
RUN git checkout  ${event_emitter_git_tag} && \
    install -d -v -m755 -o keycloak -g keycloak /opt/keycloak/keycloak/modules/system/layers/eventemitter && \
    install -d -v -m755 -o keycloak -g keycloak /opt/keycloak/keycloak/modules/system/layers/eventemitter/io/ && \
    install -d -v -m755 -o keycloak -g keycloak /opt/keycloak/keycloak/modules/system/layers/eventemitter/io/cloudtrust/ && \
    install -d -v -m755 -o keycloak -g keycloak /opt/keycloak/keycloak/modules/system/layers/eventemitter/io/cloudtrust/keycloak/ && \
    install -d -v -m755 -o keycloak -g keycloak /opt/keycloak/keycloak/modules/system/layers/eventemitter/io/cloudtrust/keycloak/eventemitter/ && \
    install -d -v -m755 -o keycloak -g keycloak /opt/keycloak/keycloak/modules/system/layers/eventemitter/io/cloudtrust/keycloak/eventemitter/main/ && \
    install -v -m0755 -o keycloak -g keycloak deploy/io/cloudtrust/keycloak/eventemitter/main/* /opt/keycloak/keycloak/modules/system/layers/eventemitter/io/cloudtrust/keycloak/eventemitter/main/ && \
    install -d -v -m755 -o keycloak -g keycloak /opt/keycloak/keycloak/modules/system/layers/eventemitter/org && \
    install -d -v -m755 -o keycloak -g keycloak /opt/keycloak/keycloak/modules/system/layers/eventemitter/org/apache && \
    install -d -v -m755 -o keycloak -g keycloak /opt/keycloak/keycloak/modules/system/layers/eventemitter/org/apache/commons && \
    install -d -v -m755 -o keycloak -g keycloak /opt/keycloak/keycloak/modules/system/layers/eventemitter/org/apache/commons/collections4 && \
    install -d -v -m755 -o keycloak -g keycloak /opt/keycloak/keycloak/modules/system/layers/eventemitter/org/apache/commons/collections4/main && \
    install -v -m0755 -o keycloak -g keycloak deploy/org/apache/commons/collections4/main/* /opt/keycloak/keycloak/modules/system/layers/eventemitter/org/apache/commons/collections4/main && \
    install -d -v -m755 -o keycloak -g keycloak /opt/keycloak/keycloak/modules/system/layers/eventemitter/com && \
    install -d -v -m755 -o keycloak -g keycloak /opt/keycloak/keycloak/modules/system/layers/eventemitter/com/google && \
    install -d -v -m755 -o keycloak -g keycloak /opt/keycloak/keycloak/modules/system/layers/eventemitter/com/google/guava && \
    install -d -v -m755 -o keycloak -g keycloak /opt/keycloak/keycloak/modules/system/layers/eventemitter/com/google/guava/main && \
    install -v -m0755 -o keycloak -g keycloak deploy/com/google/guava/main/* /opt/keycloak/keycloak/modules/system/layers/eventemitter/com/google/guava/main/

WORKDIR /cloudtrust/config
RUN git checkout ${config_git_tag} && \
    install -v -m0755 -o keycloak -g keycloak deploy/opt/keycloak/keycloak/standalone/configuration/keycloak-add-user.json /opt/keycloak/keycloak/standalone/configuration/keycloak-add-user.json && \
    install -v -m0644 -o keycloak -g keycloak deploy/opt/keycloak/keycloak/standalone/configuration/standalone.xml /opt/keycloak/keycloak/standalone/configuration/standalone.xml && \
    install -d -v -o root -g root /opt/keycloak-bridge/conf && \
    install -v -o root -g root deploy/opt/keycloak-bridge/conf/keycloak_bridge.yaml /opt/keycloak-bridge/conf/ && \
    install -v -o root -g root deploy/etc/systemd/system/keycloak_bridge.service /etc/systemd/system/ && \
    install -d -v -o root -g root /etc/systemd/system/keycloak_bridge.d && \
    install -v -m0755 -o agent -g agent deploy/etc/jaeger-agent/agent.yml /etc/agent/

#Enable services
RUN systemctl enable nginx.service && \
    systemctl enable keycloak.service && \
    systemctl enable monit.service && \
    systemctl enable agent.service && \
    systemctl enable keycloak_bridge
