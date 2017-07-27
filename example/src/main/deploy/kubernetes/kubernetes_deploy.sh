#!/bin/sh

# Copyright (c) 2017 Red Hat and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#    Red Hat - initial creation
#    Bosch Software Innovations GmbH

# Absolute path this script is in
SCRIPTPATH="$(cd "$(dirname "$0")" && pwd -P)"
HONO_HOME=$SCRIPTPATH/../../../..
CONFIG=$SCRIPTPATH/../../config
CERTS=$CONFIG/hono-demo-certs-jar
NS=hono

echo DEPLOYING ECLIPSE HONO TO KUBERNETES

# creating Hono namespace
kubectl create namespace $NS

echo
echo Deploying Grafana ...
kubectl create -f $HONO_HOME/metrics/target/classes/META-INF/fabric8/kubernetes.yml --namespace $NS
echo ... done

echo
echo Deploying Artemis broker ...
kubectl create -f $HONO_HOME/broker/target/classes/META-INF/fabric8/kubernetes.yml --namespace $NS
echo ... done

echo
echo Deploying Qpid Dispatch Router ...
kubectl create secret generic hono-dispatch-router-conf \
  --from-file=$CERTS/qdrouter-key.pem \
  --from-file=$CERTS/qdrouter-cert.pem \
  --from-file=$CERTS/trusted-certs.pem \
  --from-file=$CONFIG/hono-dispatch-router-jar/qpid/qdrouterd-with-broker.json \
  --from-file=$CONFIG/hono-dispatch-router-jar/sasl/qdrouter-sasl.conf \
  --from-file=$CONFIG/hono-dispatch-router-jar/sasl/qdrouterd.sasldb \
  --namespace $NS
kubectl create -f $CONFIG/hono-dispatch-router-jar/META-INF/fabric8/kubernetes.yml --namespace $NS
echo ... done

echo
echo Deploying Authentication Server ...
kubectl create secret generic hono-service-auth-conf \
  --from-file=$CERTS/auth-server-key.pem \
  --from-file=$CERTS/auth-server-cert.pem \
  --from-file=$CERTS/trusted-certs.pem \
  --from-file=application.yml=$CONFIG/hono-service-auth-config.yml \
  --namespace $NS
kubectl create -f $CONFIG/hono-service-auth-jar/META-INF/fabric8/kubernetes.yml --namespace $NS
echo ... done

echo
echo Deploying Device Registry ...
kubectl create secret generic hono-service-device-registry-conf \
  --from-file=$CERTS/device-registry-key.pem \
  --from-file=$CERTS/device-registry-cert.pem \
  --from-file=$CERTS/auth-server-cert.pem \
  --from-file=$CERTS/trusted-certs.pem \
  --from-file=application.yml=$CONFIG/hono-service-device-registry-config.yml \
  --namespace $NS
kubectl create -f $CONFIG/hono-service-device-registry-jar/META-INF/fabric8/kubernetes.yml --namespace $NS
echo ... done

echo
echo Deploying Hono Messaging ...
kubectl create secret generic hono-service-messaging-conf \
  --from-file=$CERTS/hono-messaging-key.pem \
  --from-file=$CERTS/hono-messaging-cert.pem \
  --from-file=$CERTS/auth-server-cert.pem \
  --from-file=$CERTS/trusted-certs.pem \
  --from-file=application.yml=$CONFIG/hono-service-messaging-config.yml \
  --namespace $NS
kubectl create -f $CONFIG/hono-service-messaging-jar/META-INF/fabric8/kubernetes.yml --namespace $NS
echo ... done

echo
echo Deploying HTTP REST adapter ...
kubectl create -f $HONO_HOME/adapters/rest-vertx/target/classes/META-INF/fabric8/kubernetes.yml --namespace $NS
echo ... done

echo
echo Deploying MQTT adapter ...
kubectl create -f $HONO_HOME/adapters/mqtt-vertx/target/classes/META-INF/fabric8/kubernetes.yml --namespace $NS
echo ... done

echo ECLIPSE HONO DEPLOYED TO KUBERNETES
