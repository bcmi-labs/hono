#!/bin/sh

# Copyright (c) 2017 Bosch Software Innovations GmbH and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#    Bosch Software Innovations GmbH - initial creation

# Absolute path this script is in
SCRIPTPATH="$(cd "$(dirname "$0")" && pwd -P)"
CONFIG=$SCRIPTPATH/../config
CERTS=$CONFIG/hono-demo-certs-jar
NS=hono
CREATE_OPTIONS="-l project=$NS --network $NS --detach=false"

echo DEPLOYING ECLIPSE HONO SANDBOX TO DOCKER SWARM

# creating Hono network
docker network create --label project=$NS --driver overlay $NS

docker secret create -l project=$NS trusted-certs.pem $CERTS/trusted-certs.pem

echo
echo Deploying Influx DB and Grafana ...
docker secret create -l project=$NS influxdb.conf $CONFIG/influxdb.conf
docker service create $CREATE_OPTIONS --name influxdb \
  --secret influxdb.conf \
  influxdb:${influxdb.version} -config /run/secrets/influxdb.conf
docker service create $CREATE_OPTIONS --name grafana -p 3001:3000 eclipsehono/grafana:${project.version}
echo ... done

echo
echo Deploying Artemis broker ...
docker secret create -l $NS artemis-broker.xml $SCRIPTPATH/artemis/artemis-broker.xml
docker secret create -l $NS artemis-bootstrap.xml $CONFIG/hono-artemis-jar/etc/artemis-bootstrap.xml
docker secret create -l $NS artemis-users.properties $CONFIG/hono-artemis-jar/etc/artemis-users.properties
docker secret create -l $NS artemis-roles.properties $CONFIG/hono-artemis-jar/etc/artemis-roles.properties
docker secret create -l $NS login.config $CONFIG/hono-artemis-jar/etc/login.config
docker secret create -l $NS logging.properties $CONFIG/hono-artemis-jar/etc/logging.properties
docker secret create -l $NS artemis.profile $SCRIPTPATH/artemis/artemis.profile
docker secret create -l $NS artemisKeyStore.p12 $CERTS/artemisKeyStore.p12
docker secret create -l $NS trustStore.jks $CERTS/trustStore.jks
docker service create $CREATE_OPTIONS --name hono-artemis \
  --env ARTEMIS_CONFIGURATION=/run/secrets \
  --secret artemis-broker.xml \
  --secret artemis-bootstrap.xml \
  --secret artemis-users.properties \
  --secret artemis-roles.properties \
  --secret login.config \
  --secret logging.properties \
  --secret artemis.profile \
  --secret artemisKeyStore.p12 \
  --secret trustStore.jks \
  --entrypoint "/opt/artemis/bin/artemis run xml:/run/secrets/artemis-bootstrap.xml" \
  ${artemis.image.name}
echo ... done

echo
echo Deploying Qpid Dispatch Router ...
docker secret create -l project=$NS qdrouter-key.pem $CERTS/qdrouter-key.pem
docker secret create -l project=$NS qdrouter-cert.pem $CERTS/qdrouter-cert.pem
docker secret create -l project=$NS qdrouterd.json $SCRIPTPATH/sandbox-qdrouterd.json
docker secret create -l project=$NS qdrouter-sasl.conf $CONFIG/hono-dispatch-router-jar/sasl/qdrouter-sasl.conf
docker secret create -l project=$NS qdrouterd.sasldb $CONFIG/hono-dispatch-router-jar/sasl/qdrouterd.sasldb
docker service create $CREATE_OPTIONS --name hono-dispatch-router -p 15671:5671 -p 15672:5672 \
  --secret qdrouter-key.pem \
  --secret qdrouter-cert.pem \
  --secret trusted-certs.pem \
  --secret qdrouterd.json \
  --secret qdrouter-sasl.conf \
  --secret qdrouterd.sasldb \
  ${dispatch-router.image.name} /sbin/qdrouterd -c /run/secrets/qdrouterd.json
echo ... done

echo
echo Deploying Authentication Server ...
docker secret create -l project=$NS auth-server-key.pem $CERTS/auth-server-key.pem
docker secret create -l project=$NS auth-server-cert.pem $CERTS/auth-server-cert.pem
docker secret create -l project=$NS hono-service-auth-config.yml $SCRIPTPATH/hono-service-auth-config.yml
docker secret create -l project=$NS sandbox-permissions.json $SCRIPTPATH/sandbox-permissions.json
docker service create $CREATE_OPTIONS --name hono-service-auth \
  --secret auth-server-key.pem \
  --secret auth-server-cert.pem \
  --secret trusted-certs.pem \
  --secret sandbox-permissions.json \
  --secret hono-service-auth-config.yml \
  --env SPRING_CONFIG_LOCATION=file:///run/secrets/hono-service-auth-config.yml \
  --env SPRING_PROFILES_ACTIVE=authentication-impl,prod \
  --env LOGGING_CONFIG=classpath:logback-spring.xml \
  eclipsehono/hono-service-auth:${project.version}
echo ... done

echo
echo Deploying Device Registry ...
docker secret create -l project=$NS device-registry-key.pem $CERTS/device-registry-key.pem
docker secret create -l project=$NS device-registry-cert.pem $CERTS/device-registry-cert.pem
docker secret create -l project=$NS hono-service-device-registry-config.yml $SCRIPTPATH/hono-service-device-registry-config.yml
docker secret create -l project=$NS example-credentials.json $CONFIG/example-credentials.json
docker service create $CREATE_OPTIONS --name hono-service-device-registry -p 25671:5671 -p 28080:8080 -p 28443:8443 \
  --secret device-registry-key.pem \
  --secret device-registry-cert.pem \
  --secret auth-server-cert.pem \
  --secret trusted-certs.pem \
  --secret hono-service-device-registry-config.yml \
  --secret example-credentials.json \
  --env SPRING_CONFIG_LOCATION=file:///run/secrets/hono-service-device-registry-config.yml \
  --env LOGGING_CONFIG=classpath:logback-spring.xml \
  --env SPRING_PROFILES_ACTIVE=prod \
  eclipsehono/hono-service-device-registry:${project.version}
echo ... done

echo
echo Deploying Hono Messaging ...
docker secret create -l project=$NS hono-messaging-key.pem $CERTS/hono-messaging-key.pem
docker secret create -l project=$NS hono-messaging-cert.pem $CERTS/hono-messaging-cert.pem
docker secret create -l project=$NS hono-service-messaging-config.yml $CONFIG/hono-service-messaging-config.yml
docker service create $CREATE_OPTIONS --name hono-service-messaging \
  --secret hono-messaging-key.pem \
  --secret hono-messaging-cert.pem \
  --secret auth-server-cert.pem \
  --secret trusted-certs.pem \
  --secret hono-service-messaging-config.yml \
  --env SPRING_CONFIG_LOCATION=file:///run/secrets/hono-service-messaging-config.yml \
  --env LOGGING_CONFIG=classpath:logback-spring.xml \
  --env SPRING_PROFILES_ACTIVE=prod \
  eclipsehono/hono-service-messaging:${project.version}
echo ... done

echo
echo Deploying HTTP REST adapter ...
docker secret create -l project=$NS rest-adapter-key.pem $CERTS/rest-adapter-key.pem
docker secret create -l project=$NS rest-adapter-cert.pem $CERTS/rest-adapter-cert.pem
docker secret create -l project=$NS hono-adapter-rest-vertx-config.yml $CONFIG/hono-adapter-rest-vertx-config.yml
docker service create $CREATE_OPTIONS --name hono-adapter-rest-vertx -p 8080:8080 -p 8443:8443 \
  --secret rest-adapter-key.pem \
  --secret rest-adapter-cert.pem \
  --secret trusted-certs.pem \
  --secret hono-adapter-rest-vertx-config.yml \
  --env SPRING_CONFIG_LOCATION=file:///run/secrets/hono-adapter-rest-vertx-config.yml \
  --env SPRING_PROFILES_ACTIVE=prod \
  --env LOGGING_CONFIG=classpath:logback-spring.xml \
  eclipsehono/hono-adapter-rest-vertx:${project.version}
echo ... done

echo
echo Deploying MQTT adapter ...
docker secret create -l project=$NS mqtt-adapter-key.pem $CERTS/mqtt-adapter-key.pem
docker secret create -l project=$NS mqtt-adapter-cert.pem $CERTS/mqtt-adapter-cert.pem
docker secret create -l project=$NS hono-adapter-mqtt-vertx-config.yml $CONFIG/hono-adapter-mqtt-vertx-config.yml
docker service create $CREATE_OPTIONS --name hono-adapter-mqtt-vertx -p 1883:1883 -p 8883:8883 \
  --secret mqtt-adapter-key.pem \
  --secret mqtt-adapter-cert.pem \
  --secret trusted-certs.pem \
  --secret hono-adapter-mqtt-vertx-config.yml \
  --env SPRING_CONFIG_LOCATION=file:///run/secrets/hono-adapter-mqtt-vertx-config.yml \
  --env SPRING_PROFILES_ACTIVE=prod \
  --env LOGGING_CONFIG=classpath:logback-spring.xml \
  eclipsehono/hono-adapter-mqtt-vertx:${project.version}
echo ... done

echo
echo "Deploying NGINX for redirecting to Hono web site"
docker service create --detach=false --name hono-nginx -p 80:80 \
  --env SERVER_REDIRECT=www.eclipse.org \
  --env SERVER_REDIRECT_PATH=/hono/sandbox \
  schmunk42/nginx-redirect
echo ... done

echo ECLIPSE HONO SANDBOX DEPLOYED TO DOCKER SWARM
