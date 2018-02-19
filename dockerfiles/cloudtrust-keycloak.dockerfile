FROM cloudtrust-baseimage:f27

ARG keycloak_service_git_tag

#Get dependencies and put keycloak where we expect it to be
RUN dnf install -y java java-1.8.0-openjdk.x86_64 monit git nginx vim wget && dnf clean all && \
    groupadd keycloak && \
    useradd -m -s /sbin/nologin -g keycloak keycloak && \
    install -d -v -m755 /opt/keycloak -o root -g root && \
    install -d -v -m755 /opt/keycloak/archive -o root -g root && \
    cd /opt/keycloak/archive && \
    wget https://downloads.jboss.org/keycloak/3.4.3.Final/keycloak-3.4.3.Final.tar.gz && \
    tar -xzf keycloak-3.4.3.Final.tar.gz && \
    mv -v keycloak-3.4.3.Final keycloak && \
    mv keycloak /opt/keycloak/ && \
    chmod 775 -R /opt/keycloak/ && \
    chown -R root:keycloak /opt/keycloak/

WORKDIR /opt
RUN \
    git clone git@github.com:cloudtrust/keycloak-service.git && \
    cd keycloak-service && \
    git checkout ${keycloak_service_git_tag}

WORKDIR /opt
RUN \
    git clone git@github.com:cloudtrust/event-emitter.git && \
    cd event-emitter && \
    git checkout 546df8070da8b0f1a99341e0e571d43f4a8669cb

WORKDIR /opt/keycloak-service
#Install keycloak
RUN install -d -v -m755 /opt/keycloak/realmsdump -o keycloak -g keycloak && \
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
    install -v -m0755 -o keycloak -g keycloak deploy/common/opt/keycloak/keycloak/modules/layers.conf /opt/keycloak/keycloak/modules/layers.conf

RUN install -v -m0775 -o root -g keycloak -d /opt/keycloak/keycloak/modules/system/layers/keycloak/org/postgresql && \
    install -v -m0775 -o root -g keycloak -d /opt/keycloak/keycloak/modules/system/layers/keycloak/org/postgresql/main && \
    install -v -m0775 -o root -g keycloak deploy/common/opt/keycloak/keycloak/modules/system/layers/keycloak/org/postgresql/main/* /opt/keycloak/keycloak/modules/system/layers/keycloak/org/postgresql/main/

#Install wsfed modules
RUN install -d -v -m755 /opt/keycloak/keycloak/modules/system/layers/wsfed -o keycloak -g keycloak && \
    install -d -v -m755 /opt/keycloak/keycloak/modules/system/layers/wsfed/com/quest/keycloak-wsfed/main/ -o keycloak -g keycloak && \
    install -v -m0755 -o keycloak -g keycloak -D deploy/common/opt/keycloak/keycloak/modules/system/layers/wsfed/com/quest/keycloak-wsfed/main/* /opt/keycloak/keycloak/modules/system/layers/wsfed/com/quest/keycloak-wsfed/main 

# Install sentry module
RUN install -d -v -m755 /opt/keycloak/keycloak/modules/system/layers/sentry -o keycloak -g keycloak && \
    install -d -v -m755 /opt/keycloak/keycloak/modules/system/layers/sentry/io/sentry/main/ -o keycloak -g keycloak && \
    install -d -v -m755 /opt/keycloak/keycloak/modules/system/layers/sentry/io/sentry/log4j/main/ -o keycloak -g keycloak && \
    install -v -m0755 -o keycloak -g keycloak -D deploy/common/opt/keycloak/keycloak/modules/system/layers/sentry/io/sentry/main/* /opt/keycloak/keycloak/modules/system/layers/sentry/io/sentry/main/ && \
    install -v -m0755 -o keycloak -g keycloak -D deploy/common/opt/keycloak/keycloak/modules/system/layers/sentry/io/sentry/log4j/main/* /opt/keycloak/keycloak/modules/system/layers/sentry/io/sentry/log4j/main/


WORKDIR /opt/event-emitter
#Keycloak event emitter install
RUN install -d -v -m755 -o keycloak -g keycloak /opt/keycloak/keycloak/modules/system/layers/eventemitter && \
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

#Enable services
RUN systemctl enable nginx.service && \
    systemctl enable keycloak.service && \
    systemctl enable monit.service

