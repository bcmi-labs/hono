#!/bin/bash

BRANCH=$1

git clone https://github.com/bcmi-labs/hono.git && cd /hono && git checkout $BRANCH

mvn clean install -Ddocker.host=tcp://172.18.0.1:2375 -Pbuild-docker-image
mkdir -p /usr/local/src/hono
cp -pr /hono/example/target /usr/local/src/hono/
ls /usr/local/src
