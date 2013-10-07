#!/usr/bin/env bash

apt-get -y update
apt-get -y install ruby-bundler
apt-get -y install ruby-dev
apt-get -y install mongodb-server

# libxml2 and libxslt, for nokogiri
apt-get -y install libxml2-dev
apt-get -y install libxslt-dev
