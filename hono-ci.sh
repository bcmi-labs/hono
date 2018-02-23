#!/bin/bash

mvn clean install -Ddocker.host=tcp://172.18.0.1:2375 -Pbuild-docker-image -f hono/pom.xml
ls /usr/local/src
mkdir -p /usr/local/src/hono
cp -pr /hono/example/target /usr/local/src/hono/
ls /usr/local/src
