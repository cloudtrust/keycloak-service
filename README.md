# Keycloak

This repository contains our keycloak dockerfile. For our needs, it makes sense to have as little dynamic parts as possible. Keycloak being a stateless frontend, we only need to manage the modules we add, and keycloak's configuration. We also need to integrate our keycloak_bridge in the image.


## Building the dockerfile

We recommend running the build tasks via our deployment procedure, but in case you want to build it yourself, there are many build arguments to pass. You can learn about them by reading the dockerfile.

## Running keycloak

Depending on the config repo, the container could expect some names to be reachable. Refer to the specifics of the configuration repo.

An example run command should look like

```Bash
#Run the container
docker run --rm -it --net=ct_bridge --tmpfs /tmp --tmpfs /run -v /sys/fs/cgroup:/sys/fs/cgroup:ro --name keycloak -p 8080:80 cloudtrust-keycloak
```

# Notes on keycloak

OpenID Connect Direct access grant is named "Resource Owner Password credentials grant" in
OAuth2 specification

https://github.com/iuliazidaru/keycloak-spring-boot-rest-angular-demo

http://slackspace.de/articles/authentication-with-spring-boot-angularjs-and-keycloak/

https://github.com/foo4u/keycloak-spring-demo

https://github.com/dasniko/keycloak-springboot-demo

https://github.com/cternes/slackspace-angular-spring-keycloak

https://github.com/borysn/spring-boot-angular2

https://github.com/keycloak/keycloak/tree/fc6d6ff7f7dae7fb25edf052659d18cd8de55a5f/examples/demo-template/angular2-product-app

http://paulbakker.io/java/jwt-keycloak-angular2/

https://github.com/paulbakker/vertx-angular2-keycloak-demo

https://github.com/wpic/sample-keycloak-getting-token
