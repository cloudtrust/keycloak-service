FROM cloudtrust-baseimage:f27

ARG keycloak_service_git_tag
ARG event_emitter_git_tag
ARG jaeger_release 
ARG config_env
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
RUN wget ${jaeger_release} && \
    tar -xzf v1.2.0.tar.gz && \
    mv -v v1.2.0 jaeger && \
    install -v -m0755 jaeger/agent-linux /etc/agent/agent && \
    rm v1.2.0.tar.gz && \
    rm -rf jaeger/

RUN git clone git@github.com:cloudtrust/keycloak-service.git && \
    git clone git@github.com:cloudtrust/event-emitter.git && \
    git clone ${config_repo} ./config 

WORKDIR /cloudtrust/keycloak-service
RUN git checkout ${keycloak_service_git_tag} && \
    install -d -v -m755 /opt/keycloak/realmsdump -o keycloak -g keycloak && \
    install -d -v -m755 /opt/keycloak/keycloak/standalone/log -o keycloak -g keycloak && \
    install -d -v -m755 /opt/keycloak/keycloak/standalone/tmp -o keycloak -g keycloak && \
    install -d -v -m755 /opt/keycloak/keycloak/standalone/data -o keycloak -g keycloak && \
    install -d -v -m755 /opt/keycloak/keycloak/standalone/configuration -o keycloak -g keycloak && \
    install -v -m0644 deploy/common/etc/security/limits.d/* /etc/security/limits.d/ && \
    install -v -m0644 deploy/common/etc/security/limits.d/01-nginx.conf /etc/security/limits.d/01-nginx.conf && \
#install monit
    install -v -m0644 deploy/common/etc/monit.d/* /etc/monit.d/ && \
#nginx setup
    install -v -m0644 -D deploy/common/etc/nginx/conf.d/* /etc/nginx/conf.d/ && \
    install -v -m0644 deploy/common/etc/nginx/nginx.conf /etc/nginx/nginx.conf && \
    install -v -m0644 deploy/common/etc/nginx/mime.types /etc/nginx/mime.types && \
    install -v -o root -g root -m 644 -d /etc/systemd/system/nginx.service.d && \
    install -v -o root -g root -m 644 deploy/common/etc/systemd/system/nginx.service.d/limit.conf /etc/systemd/system/nginx.service.d/limit.conf && \
#keycloak config
    install -v -m0755 -d /etc/keycloak && \
    install -v -m0744 -d /run/keycloak && \
    install -v -m0755 deploy/common/etc/keycloak/* /etc/keycloak && \
    install -v -m0755 -o keycloak -g keycloak -D deploy/common/opt/keycloak/keycloak/standalone/bin/standalone.conf /opt/keycloak/keycloak/bin && \
    install -v -m0755 -o keycloak -g keycloak -D deploy/common/opt/keycloak/keycloak/standalone/configuration/standalone.xml /opt/keycloak/keycloak/standalone/configuration && \
    install -v -o root -g root -m 644 -d /etc/systemd/system/keycloak.service.d && \
    install -v -o root -g root -m 644 deploy/common/etc/systemd/system/keycloak.service.d/limit.conf /etc/systemd/system/keycloak.service.d/limit.conf && \
    install -v -o root -g root -m 644 deploy/common/etc/systemd/system/keycloak.service /etc/systemd/system/keycloak.service && \
    install -v -m0755 -o keycloak -g keycloak /opt/keycloak/keycloak/docs/contrib/scripts/systemd/launch.sh /opt/keycloak/keycloak/bin/ && \
#Enable the new layers
    install -v -m0755 -o keycloak -g keycloak deploy/common/opt/keycloak/keycloak/modules/layers.conf /opt/keycloak/keycloak/modules/layers.conf && \
    install -v -m0775 -o root -g keycloak -d /opt/keycloak/keycloak/modules/system/layers/keycloak/org/postgresql && \
    install -v -m0775 -o root -g keycloak -d /opt/keycloak/keycloak/modules/system/layers/keycloak/org/postgresql/main && \
    install -v -m0775 -o root -g keycloak deploy/common/opt/keycloak/keycloak/modules/system/layers/keycloak/org/postgresql/main/* /opt/keycloak/keycloak/modules/system/layers/keycloak/org/postgresql/main/ && \
    install -d -v -m755 /opt/keycloak/keycloak/modules/system/layers/wsfed -o keycloak -g keycloak && \
    install -d -v -m755 /opt/keycloak/keycloak/modules/system/layers/wsfed/com/quest/keycloak-wsfed/main/ -o keycloak -g keycloak && \
    install -v -m0755 -o keycloak -g keycloak -D deploy/common/opt/keycloak/keycloak/modules/system/layers/wsfed/com/quest/keycloak-wsfed/main/* /opt/keycloak/keycloak/modules/system/layers/wsfed/com/quest/keycloak-wsfed/main && \
    install -d -v -m755 /opt/keycloak/keycloak/modules/system/layers/sentry -o keycloak -g keycloak && \
    install -d -v -m755 /opt/keycloak/keycloak/modules/system/layers/sentry/io/sentry/main/ -o keycloak -g keycloak && \
    install -d -v -m755 /opt/keycloak/keycloak/modules/system/layers/sentry/io/sentry/log4j/main/ -o keycloak -g keycloak && \
    install -v -m0755 -o keycloak -g keycloak -D deploy/common/opt/keycloak/keycloak/modules/system/layers/sentry/io/sentry/main/* /opt/keycloak/keycloak/modules/system/layers/sentry/io/sentry/main/ && \
    install -v -m0755 -o keycloak -g keycloak -D deploy/common/opt/keycloak/keycloak/modules/system/layers/sentry/io/sentry/log4j/main/* /opt/keycloak/keycloak/modules/system/layers/sentry/io/sentry/log4j/main/ && \
# jaeger-agent
    install -v -o agent -g agent -m 644 deploy/common/etc/systemd/system/agent.service /etc/systemd/system/agent.service && \
    install -v -o root -g root -m 644 -d /etc/systemd/system/agent.service.d && \
    install -v -o root -g root -m 644 deploy/common/etc/systemd/system/agent.service.d/limit.conf /etc/systemd/system/agent.service.d/limit.conf

WORKDIR /cloudtrust/event-emitter
RUN git checkout  ${event_emitter_git_tag} && \
    install -d -v -m755 -o keycloak -g keycloak /opt/keycloak/keycloak/modules/system/layers/eventemitter && \
    install -d -v -m755 -o keycloak -g keycloak /opt/keycloak/keycloak/modules/system/layers/eventemitter/io/ && \
    install -d -v -m755 -o keycloak -g keycloak /opt/keycloak/keycloak/modules/system/layers/eventemitter/io/cloudtrust/ && \
    install -d -v -m755 -o keycloak -g keycloak /opt/keycloak/keycloak/modules/system/layers/eventemitter/io/cloudtrust/keycloak/ && \
    install -d -v -m755 -o keycloak -g keycloak /opt/keycloak/keycloak/modules/system/layers/eventemitter/io/cloudtrust/keycloak/eventemitter/ && \
    install -d -v -m755 -o keycloak -g keycloak /opt/keycloak/keycloak/modules/system/layers/eventemitter/io/cloudtrust/keycloak/eventemitter/main/ && \
    install -v -m0755 -o keycloak -g keycloak deploy/io/cloudtrust/keycloak/eventemitter/main/* /opt/keycloak/keycloak/modules/system/layers/eventemitter/io/cloudtrust/keycloak/eventemitter/main/ && \
#Event emitter dependecies
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
    install -v -m0755 -o keycloak -g keycloak deploy/${config_env}/opt/keycloak/keycloak/standalone/configuration/keycloak-add-user.json /opt/keycloak/keycloak/standalone/configuration/keycloak-add-user.json && \
    install -v -m0644 -o keycloak -g keycloak deploy/${config_env}/opt/keycloak/keycloak/standalone/configuration/standalone.xml /opt/keycloak/keycloak/standalone/configuration/standalone.xml && \
    install -v -d -o root -g root /opt/keycloak-bridge && \
    install -v -d -o root -g root /opt/keycloak-bridge/conf && \
    install -v -o root -g root deploy/${config_env}/opt/keycloak-bridge/conf/keycloak_bridge.yaml /opt/keycloak-bridge/conf/ && \
    install -v -o root -g root deploy/${config_env}/opt/keycloak-bridge/keycloakd /opt/keycloak-bridge && \
    install -v -o root -g root deploy/${config_env}/etc/systemd/system/keycloak_bridge.service /etc/systemd/system/ && \
    install -v -d -o root -g root /etc/systemd/system/keycloak_bridge.d && \
    install -v -m0755 -o agent -g agent deploy/${config_env}/etc/jaeger-agent/agent.yml /etc/agent/

#Enable services
RUN systemctl enable nginx.service && \
    systemctl enable keycloak.service && \
    systemctl enable monit.service && \
    systemctl enable agent.service && \
    systemctl enable keycloak_bridge
