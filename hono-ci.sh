#!/bin/bash

mvn clean install -Ddocker.host=tcp://172.18.0.1:2375 -Pbuild-docker-image -f hono/pom.xml
mkdir -p /opt/hono
cp -pr /hono/example/target /opt/hono
