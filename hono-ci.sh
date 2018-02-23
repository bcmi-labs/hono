#!/bin/bash

mvn clean install -Ddocker.host=tcp://172.18.0.1:2375 -Pbuild-docker-image
mkdir -p /opt/hono
cp -pr example/target /opt/hono
