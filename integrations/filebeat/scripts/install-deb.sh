#!/bin/bash

FILEBEAT_VERSION=${FILEBEAT_VERSION:-7.11.1}
FILEBEAT_ARCH=$(dpkg --print-architecture)

echo "Installing dependencies..."
apt-get update
apt-get install -y curl

echo "Installing Filebeat $FILEBEAT_VERSION..."
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-$FILEBEAT_VERSION-$FILEBEAT_ARCH.deb
dpkg -i filebeat-$FILEBEAT_VERSION-$FILEBEAT_ARCH.deb
rm filebeat-$FILEBEAT_VERSION-$FILEBEAT_ARCH.deb

echo "Copying configuration file..."
cp $(dirname $0)/filebeat.yml /etc/filebeat/filebeat.yml
chown root:root /etc/filebeat/filebeat.yml
chmod 600 /etc/filebeat/filebeat.yml

echo "Downloading SSL certificate..."
mkdir -p /usr/share/ca-certificates/coralogix
curl -o /usr/share/ca-certificates/coralogix/ca.crt \
     https://coralogix-public.s3-eu-west-1.amazonaws.com/certificate/ca.crt

echo "Starting Filebeat..."
update-rc.d filebeat defaults
update-rc.d filebeat enable
service filebeat start
service filebeat status
