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
docker run -d -v /var/lib/grafana --name grafana-storage busybox:latest

# Create Grafana Docker
docker create \
--name=grafana \
-p 3000:3000 \
--volumes-from grafana-storage \
-e "GF_SECURITY_ADMIN_PASSWORD=hunter2" \
grafana/grafana

# Start Grafana Docker
docker start grafana

# Make Bin folder
sudo mkdir ~/bin

# Download Update Script
sudo wget https://gist.githubusercontent.com/tylerhammer/205f0e4096ee0381138bbbed6a6b46d0/raw/8a3d92c678aac90be63ada60f45a40f66090c693/grafanaupdate.sh -O ~/bin/updategrafana.sh

# Create Auto Start Service
sudo wget https://gist.githubusercontent.com/tylerhammer/0cce375aa7db436ac69369014e2e27ed/raw/2e581aa1d3dd4857fe7ba5f66bbfd20b9699c5cf/grafana.service -O /lib/systemd/system/grafana.service

# Enable Grafana Service
systemctl enable grafana.service

# InfluxDB - Docker - Ubuntu 16.04

# Create Local Storage
sudo mkdir -p /docker/containers/influxdb/conf/
sudo mkdir -p /docker/containers/influxdb/db/

# Check Ownership
sudo chown root:root -R /docker

# Generate Default Config
docker run --rm influxdb influxd config > /docker/containers/influxdb/conf/influxdb.conf

# Create InfluxDB Container
docker create \
--name influxdb \
-e PUID=1000 -e PGID=1000 \
-p 8083:8083 -p 8086:8086 \
-v /docker/containers/influxdb/conf/influxdb.conf:/etc/influxdb/influxdb.conf:ro \
-v /docker/containers/influxdb/db:/var/lib/influxdb \
influxdb -config /etc/influxdb/influxdb.conf

# Start InfluxDB
docker start influxdb

# Create Update Script
wget https://gist.githubusercontent.com/tylerhammer/f5b3c291480efab4d10cea84073c2e24/raw/1cdc374574c322ad3fafd46aa417b5e4cac59e58/influxupdate.sh -O ~/bin/influxupdate.sh

# Setup Auto Start
wget https://gist.githubusercontent.com/tylerhammer/8960cb295cc8c7203da7399b8a463d94/raw/96f869255c5709c851cbac01a49093e697c86349/influxdb.service -O /lib/systemd/system/influxdb.service

# Enable Service
systemctl enable influxdb.service

# CollecD Install - Docker - Ubuntu 16.04

# Install
docker create \
  -e "SF_API_TOKEN=XXXXXXXXXXXXXXXXXXXXXX" \
  -v /etc/hostname:/mnt/hostname:ro \
  -v /proc:/mnt/proc:ro \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /etc:/mnt/etc:ro \
  quay.io/signalfuse/collectd
  
  
# Auto Start
wget https://gist.githubusercontent.com/tylerhammer/468911ffc705127693c63a3acf3ed939/raw/400cda9ededd099681c6d428256998f624b0b07c/collectd.service -O /lib/systemd/system/collectd.service

# Enable Service
systemctl enable collectd.service

# Graphite Install - Docker - Ubuntu 16.04

# Install
docker run -d\
 --name graphite\
 --restart=always\
 -p 80:80\
 -p 2003-2004:2003-2004\
 -p 2023-2024:2023-2024\
 -p 8125:8125/udp\
 -p 8126:8126\
 hopsoft/graphite-statsd
 
# Auto Start
wget https://gist.githubusercontent.com/tylerhammer/41c0305d169ca88eb712d9c3cd5fec07/raw/5c062868571951e92ab6a9697d4def26825f0780/graphite.service -O /lib/systemd/system/graphite.service

# Enable Service
systemctl enable graphite.service