#Installing keycloak
```Bash
#Get the repo
git clone git@github.com:cloudtrust/keycloak-service.git
cd keycloak-service

#Build the dockerfile
cd docker-context
docker build -t cloudtrust-keycloak -f cloudtrust-keycloak.dockerfile .

#install systemd unit file
install -v -o root -g root -m 644  ../deploy/common/etc/systemd/system/cloudtrust-keycloak@.service /etc/systemd/system/cloudtrust-keycloak@.service

#create container 1
docker create --tmpfs /tmp --tmpfs /run -v /sys/fs/cgroup:/sys/fs/cgroup:ro --name keycloak-1 -p 8080:80 cloudtrust-keycloak

#start container 1
systemctl start cloudtrust-keycloak@1
```

#Import export of realm data

##Export of realms data
Currently realm data are exported on /opt/keycloak/realmsdump

##Creat admin user
```Bash
cd /op/keycloak/keycloak
bin/add-user-keycloak.[sh|bat] -r master -u <username> -p <password>
```

##Import of realms data

Don't forget all users

```Bash
export TKN=$(curl -X POST 'http://localhost:8080/auth/realms/master/protocol/openid-connect/token' -H "Content-Type:application/x-www-form-urlencoded" -d "username=admin-curl" -d 'password=admin' -d 'grant_type=password' -d 'client_id=admin-cli' | jq -r '.access_token')

curl -X DELETE 'http://localhost:8080/auth/admin/realms/adminui' -H "Accept: application/json" -H "Authorization: Bearer $TKN"

cat adminui-realm.json | curl -H "Content-Type: application/json" -X POST -d "$(</dev/stdin)" 'http://localhost:8080/auth/admin/realms' -H "Accept: application/json" -H "Authorization: Bearer $TKN"

cat adminui-users-0.json | curl -H "Content-Type: application/json" -X POST -d "$(</dev/stdin)" 'http://localhost:8080/auth/admin/realms/adminui/partialImport' -H "Accept: application/json" -H "Authorization: Bearer $TKN"

```


## Notes 

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

For security I would separate the user that is running the service from the owner of the application files. So I prefer having everything owned by root, only give read-access to group keycloak (exception to some files/paths Keycloak requires write-access to).

