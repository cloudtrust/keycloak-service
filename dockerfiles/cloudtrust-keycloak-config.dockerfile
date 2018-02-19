ARG keycloak_service_git_tag

FROM cloudtrust-keycloak:${keycloak_service_git_tag}

ARG environment
ARG branch
ARG config_repository

WORKDIR /cloudtrust

# Get config config
RUN git clone ${config_repository} ./config && \
	cd ./config && \
    git checkout ${branch}

# Setup Customer http-router related config
############################################

WORKDIR /cloudtrust/config
RUN install -v -m0755 -o keycloak -g keycloak deploy/${environment}/opt/keycloak/keycloak/standalone/configuration/keycloak-add-user.json /opt/keycloak/keycloak/standalone/configuration/keycloak-add-user.json && \
    install -v -m0644 -o keycloak -g keycloak deploy/${environment}/opt/keycloak/keycloak/standalone/configuration/standalone.xml /opt/keycloak/keycloak/standalone/configuration/standalone.xml

RUN install -v -d -o root -g root /opt/keycloak-bridge && \
    install -v -d -o root -g root /opt/keycloak-bridge/conf && \
    install -v -o root -g root deploy/${environment}/opt/keycloak-bridge/conf/keycloak_bridge.yaml /opt/keycloak-bridge/conf/ && \
    install -v -o root -g root deploy/${environment}/opt/keycloak-bridge/keycloakd /opt/keycloak-bridge && \
    install -v -o root -g root deploy/${environment}/etc/systemd/system/keycloak_bridge.service /etc/systemd/system/ && \
    install -v -d -o root -g root /etc/systemd/system/keycloak_bridge.d && \
    systemctl enable keycloak_bridge
