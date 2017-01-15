#!/bin/bash

# Docker Installation with Grafana, InfluxDB, CollectD & Graphite
# This script includes all auto start files

# Docker Installation for Ubuntu 16.04

# Update Package Database
sudo apt-get update

# Add GPG Key for Docker Repo
sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" | sudo tee /etc/apt/sources.list.d/docker.list

# Update Database
sudo apt-get update

# Verify Repo
apt-cache policy docker-engine

# Install Docker
sudo apt-get install -y docker-engine

# Execute
sudo usermod -aG docker $(whoami)

# Grafana Install - Docker - Ubuntu 16.04

# Create Persistent Storage
sudo docker run -d -v /var/lib/grafana --name grafana-storage busybox:latest

# Create Grafana Docker
sudo docker create \
--name=grafana \
-p 3000:3000 \
--volumes-from grafana-storage \
-e "GF_SECURITY_ADMIN_PASSWORD=hunter2" \
grafana/grafana

# Start Grafana Docker
sudo docker start grafana

# Make Bin folder
sudo mkdir ~/bin

# Download Grafana Update Script
sudo wget https://raw.githubusercontent.com/tylerhammer/grafana/master/Setup%20Requirements/grafanaupdate.sh -O ~/bin/updategrafana.sh

# Create Auto Start Service
sudo wget https://raw.githubusercontent.com/tylerhammer/grafana/master/Setup%20Requirements/grafana.service -O /lib/systemd/system/grafana.service

# Enable Grafana Service
sudo systemctl enable grafana.service

# InfluxDB - Docker - Ubuntu 16.04

# Create Local Storage
sudo mkdir -p /docker/containers/influxdb/conf/
sudo mkdir -p /docker/containers/influxdb/db/

# Check Ownership
sudo chown root:root -R /docker

# Generate Default Config
sudo docker run --rm influxdb influxd config > /docker/containers/influxdb/conf/influxdb.conf

# Create InfluxDB Container
sudo docker create \
--name influxdb \
-e PUID=1000 -e PGID=1000 \
-p 8083:8083 -p 8086:8086 \
-v /docker/containers/influxdb/conf/influxdb.conf:/etc/influxdb/influxdb.conf:ro \
-v /docker/containers/influxdb/db:/var/lib/influxdb \
influxdb -config /etc/influxdb/influxdb.conf

# Start InfluxDB
sudo docker start influxdb

# Create Influx Update Script
sudo wget https://raw.githubusercontent.com/tylerhammer/grafana/master/Setup%20Requirements/influxdbupdate.sh -O ~/bin/influxupdate.sh

# Setup Auto Start
sudo wget https://raw.githubusercontent.com/tylerhammer/grafana/master/Setup%20Requirements/influxdb.service -O /lib/systemd/system/influxdb.service

# Enable Service
sudo systemctl enable influxdb.service

# CollecD Install - Docker - Ubuntu 16.04

# Install
sudo docker create \
  -e "SF_API_TOKEN=XXXXXXXXXXXXXXXXXXXXXX" \
  -v /etc/hostname:/mnt/hostname:ro \
  -v /proc:/mnt/proc:ro \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /etc:/mnt/etc:ro \
  quay.io/signalfuse/collectd
  
  
# Auto Start
sudo wget https://raw.githubusercontent.com/tylerhammer/grafana/master/Setup%20Requirements/collectd.service -O /lib/systemd/system/collectd.service

# Enable Service
sudo systemctl enable collectd.service

# Graphite Install - Docker - Ubuntu 16.04

# Install
sudo docker run -d\
 --name graphite\
 --restart=always\
 -p 80:80\
 -p 2003-2004:2003-2004\
 -p 2023-2024:2023-2024\
 -p 8125:8125/udp\
 -p 8126:8126\
 hopsoft/graphite-statsd
 
# Auto Start
sudo wget https://raw.githubusercontent.com/tylerhammer/grafana/master/Setup%20Requirements/graphite.service -O /lib/systemd/system/graphite.service

# Enable Service
sudo systemctl enable graphite.service
