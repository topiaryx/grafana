#!/bin/bash

# This script will install Docker, Grafana, InfluxDB, Graphite & CollectD. It will also add systemd service files to ensure auto startup each boot. 
# This script was created by reddit user /u/tyler_hammer. This is a combination of several guides with edits to make it as easy as possible for new people to start. 

# Checking for Root Permissions # Thanks to Github User "codygarver" for the recommendation
check_your_privilege () {
    if [[ "$(id -u)" != 0 ]]; then
        echo "Error: This setup script requires root permissions." > /dev/stderr
        exit 1
    fi
}
check_your_privilege

# Docker Installation for Ubuntu 16.04

# Update Package Database
apt-get update

# Add GPG Key for Docker Repo
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" | sudo tee /etc/apt/sources.list.d/docker.list

# Update Database
apt-get update

# Verify Repo
apt-cache policy docker-engine

# Install Docker
apt-get install -y docker-engine

# Remove the need to user Sudo before docker. This generally requires you to log out and log back in, which is why we restart at the end of the script.
usermod -aG docker $(whoami)

# Grafana Install - Docker - Ubuntu 16.04

# Create Persistent Storage
docker run -d -v /var/lib/grafana --name grafana-storage busybox:latest

# Create Grafana Docker
sudo docker create \
--name=grafana \
-p 3000:3000 \
--volumes-from grafana-storage \
-e "GF_SECURITY_ADMIN_PASSWORD=hunter2" \
grafana/grafana

# Start Grafana Docker
docker start grafana

# Make Bin folder for update scripts
mkdir ~/bin

# Download Grafana Update Script
wget https://raw.githubusercontent.com/tylerhammer/grafana/master/Setup%20Requirements/grafanaupdate.sh -O ~/bin/updategrafana.sh

# Create Auto Start Service
wget https://raw.githubusercontent.com/tylerhammer/grafana/master/Setup%20Requirements/grafana.service -O /lib/systemd/system/grafana.service

# Enable Grafana Service
systemctl enable grafana.service

# InfluxDB - Docker - Ubuntu 16.04

# Create Local Storage
mkdir -p /docker/containers/influxdb/conf/
mkdir -p /docker/containers/influxdb/db/

# Check Ownership
chown ${USER:=$(/usr/bin/id -run)}:$USER -R /docker

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

# Create Influx Update Script
wget https://raw.githubusercontent.com/tylerhammer/grafana/master/Setup%20Requirements/influxdbupdate.sh -O ~/bin/influxupdate.sh

# Setup Auto Start
wget https://raw.githubusercontent.com/tylerhammer/grafana/master/Setup%20Requirements/influxdb.service -O /lib/systemd/system/influxdb.service

# Enable Service
systemctl enable influxdb.service

# CollecD Install - Docker - Ubuntu 16.04

# Create CollectD Container
docker create \
  --name collectd\
  -e "SF_API_TOKEN=XXXXXXXXXXXXXXXXXXXXXX" \
  -v /etc/hostname:/mnt/hostname:ro \
  -v /proc:/mnt/proc:ro \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /etc:/mnt/etc:ro \
  quay.io/signalfuse/collectd
  
  
# Auto Start
wget https://raw.githubusercontent.com/tylerhammer/grafana/master/Setup%20Requirements/collectd.service -O /lib/systemd/system/collectd.service

# Enable Service
systemctl enable collectd.service

# Graphite Install - Docker - Ubuntu 16.04

# Create Graphite Container
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
wget https://raw.githubusercontent.com/tylerhammer/grafana/master/Setup%20Requirements/graphite.service -O /lib/systemd/system/graphite.service

# Enable Service
systemctl enable graphite.service

# Restart Announcment
echo Restarting VM

# Restart
reboot
