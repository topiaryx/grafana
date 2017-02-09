#!/bin/bash

# This script will install Docker, Grafana, InfluxDB, Graphite & CollectD. It will also add systemd service files to ensure auto startup each boot.
# This script was created by reddit user /u/tyler_hammer. This is a combination of several guides with edits to make it as easy as possible for new people to start.

# Checking for Root Permissions # Thanks to Github User "codygarver" for the recommendation
check_your_privilege () {
    if [[ "$(id -u)" != 0 ]]; then
        echo "Error: This setup script requires root permissions. Please run the script as root." > /dev/stderr
        exit 1
    fi
}
check_your_privilege

# Docker Installation for Ubuntu 16.04

# Update Package Database
while true; do
    echo -n -e "\e[7mDo you wish to run system updates? [y/n]:\e[0m "
    read yn
    case $yn in
        [yY] | [yY][Ee][Ss] ) echo "Okay, Update time!";  sudo apt-get -y update && sudo apt-get -y upgrade; break;; #(Run both in one line)
        [nN] | [n|N][O|o] ) echo "Fine no updates"; break;;  #Boring people don't update
        * ) echo "Please answer yes or no.";;  #Error handling to get the right answer
    esac >/dev/null 2>>install.log
done
echo -e "\e[36mContinuing with script \e[0m"  #Continue with the script

# Add GPG Key for Docker Repo
echo -e "\e[36mAdding GPG Key for Docker Repo \e[0m"

apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D >>/dev/null 2>>install.log
echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" | sudo tee /etc/apt/sources.list.d/docker.list >>/dev/null 2>>install.log

# Update Database
echo -e "\e[36mUpdating Database \e[0m"
apt-get update >>/dev/null 2>>install.log

# Verify Repo
echo -e "\e[36mVerifying Repo \e[0m"
apt-cache policy docker-engine >>/dev/null 2>>install.log

# Install Docker
echo -e "\e[36mInstalling Docker \e[0m"
apt-get install -y docker-engine >>/dev/null 2>>install.log

# Grafana Install - Docker - Ubuntu 16.04

# Create Persistent Storage
echo -e "\e[36mCreating persistent storage for Grafana \e[0m"
docker run -d -v /var/lib/grafana --name grafana-storage busybox:latest >>/dev/null 2>>install.log

# Create Grafana Docker
echo -e "\e[36mCreating Grafana docker container - This make take awhile! \e[0m"
sudo docker create \
--name=grafana \
-p 3000:3000 \
--volumes-from grafana-storage \
-e "GF_SECURITY_ADMIN_PASSWORD=hunter2" \
grafana/grafana >>/dev/null 2>>install.log

# Start Grafana Docker
echo -e "\e[36mStarting Grafana \e[0m"
docker start grafana >>/dev/null 2>>install.log

# Make Bin folder for update scripts
echo -e "\e[36mCreating Update Folder \e[0m"
mkdir ~/updates >>/dev/null 2>>install.log

# Download Grafana Update Script
echo -e "\e[36mDownloading Grafana update script \e[0m"
wget https://raw.githubusercontent.com/tylerhammer/grafana/master/Setup%20Requirements/grafanaupdate.sh -O ~/bin/updategrafana.sh >>/dev/null 2>>install.log

# Create Auto Start Service
echo -e "\e[36mCreating Grafana SystemD file\e[0m"
sudo bash -c "cat >/lib/systemd/system/grafana.service" << EOF
[Unit]
 Description=grafana container
 Requires=docker.service
 After=docker.service

[Service]
 User=root
 Restart=on-failure
 RestartSec=45
 ExecStart=/usr/bin/docker start -a grafana
 ExecStop=/usr/bin/docker stop -t 2 grafana

[Install]
 WantedBy=multi-user.target
EOF

# Enable Grafana Service
echo -e "\e[36mEnabling Grafana service \e[0m"
systemctl enable grafana.service >>/dev/null 2>>install.log

# InfluxDB - Docker - Ubuntu 16.04

# Create Local Storage
echo -e "\e[36mCreating local storage for InfluxDB \e[0m"
mkdir -p /docker/containers/influxdb/conf/ >>/dev/null 2>>install.log
mkdir -p /docker/containers/influxdb/db/ >>/dev/null 2>>install.log

# Check Ownership
echo -e "\e[36mVerifying ownership \e[0m"
chown ${USER:=$(/usr/bin/id -run)}:$USER -R /docker >>/dev/null 2>>install.log

# Generate Default Config
echo -e "\e[36mGenerating default config file for InfluxDB \e[0m"
docker run --rm influxdb influxd config > /docker/containers/influxdb/conf/influxdb.conf 2>>install.log

# Create InfluxDB Container
echo -e "\e[36mCreating InfluxDB docker container - This make take awhile! \e[0m"
docker create \
--name influxdb \
-e PUID=1000 -e PGID=1000 \
-p 8083:8083 -p 8086:8086 \
-v /docker/containers/influxdb/conf/influxdb.conf:/etc/influxdb/influxdb.conf:ro \
-v /docker/containers/influxdb/db:/var/lib/influxdb \
influxdb -config /etc/influxdb/influxdb.conf >>/dev/null 2>>install.log

# Start InfluxDB
echo -e "\e[36mStarting InfluxDB \e[0m"
docker start influxdb >>/dev/null 2>>install.log

# Create Influx Update Script
echo -e "\e[36mDownloading InfluxDB update script \e[0m"
wget https://raw.githubusercontent.com/tylerhammer/grafana/master/Setup%20Requirements/influxdbupdate.sh -O ~/bin/influxupdate.sh >>/dev/null 2>>install.log

# Setup Auto Start
echo -e "\e[36mCreating InfluxDB SystemD file\e[0m"
sudo bash -c "cat >/lib/systemd/system/influxdb.service" << EOF  2>>install.log
[Unit]
 Description=influxdb container
 Requires=docker.service
 After=docker.service

[Service]
 User=root
 Restart=on-failure
 RestartSec=45
 ExecStart=/usr/bin/docker start -a influxdb
 ExecStop=/usr/bin/docker stop -t 2 influxdb

[Install]
 WantedBy=multi-user.target
EOF

# Enable Service
echo -e "\e[36mEnabling InfluxDB Service \e[0m"
systemctl enable influxdb.service >>/dev/null 2>>install.log

# CollecD Install - Docker - Ubuntu 16.04

# Create CollectD Container
echo -e "\e[36mCreating CollectD docker container - This may take awhile! \e[0m"
docker create \
  --name collectd\
  -e "SF_API_TOKEN=XXXXXXXXXXXXXXXXXXXXXX" \
  -v /etc/hostname:/mnt/hostname:ro \
  -v /proc:/mnt/proc:ro \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /etc:/mnt/etc:ro \
  quay.io/signalfuse/collectd >>/dev/null 2>>install.log


# Auto Start
echo -e "\e[36mCreating CollectD SystemD file\e[0m"
sudo bash -c "cat >/lib/systemd/system/influxdb.service" << EOF
[Unit]
 Description=Collectd container
 Requires=docker.service
 After=docker.service

[Service]
 User=root
 Restart=on-failure
 RestartSec=45
 ExecStart=/usr/bin/docker start -a collectd
 ExecStop=/usr/bin/docker stop -t 2 collectd

[Install]
 WantedBy=multi-user.target
EOF

# Enable Service
echo -e "\e[36mEnabling CollectD Service \e[0m"
systemctl enable collectd.service >>/dev/null 2>>install.log

# Graphite Install - Docker - Ubuntu 16.04

# Create Graphite Container
echo -e "\e[36mCreating Graphite docker container - This may take awhile! \e[0m"
docker run -d\
 --name graphite\
 --restart=always\
 -p 80:80\
 -p 2003-2004:2003-2004\
 -p 2023-2024:2023-2024\
 -p 8125:8125/udp\
 -p 8126:8126\
 hopsoft/graphite-statsd >>/dev/null 2>>install.log

# Auto Start
echo -e "\e[36mCreating Graphite SystemD file\e[0m"
sudo bash -c "cat >/lib/systemd/system/influxdb.service" << EOF
[Unit]
 Description=Graphite container
 Requires=docker.service
 After=docker.service

[Service]
 User=root
 Restart=on-failure
 RestartSec=45
 ExecStart=/usr/bin/docker start -a graphite
 ExecStop=/usr/bin/docker stop -t 2 graphite

[Install]
 WantedBy=multi-user.target
EOF

# Enable Service
echo -e "\e[36mEnabling Graphite Service \e[0m"
systemctl enable graphite.service >>/dev/null 2>>install.log

# Enable InfluxDB WebUI
echo -e "\e[36mEnabling InfluxDB WebUI \e[0m"
sed -i '40s/.*/  enabled = true/' /docker/containers/influxdb/conf/influxdb.conf >>/dev/null 2>>install.log

# Install other dependencies
echo -e "\e[36mInstalling SSHPASS and SNMP dependencies - This may take awhile! \e[0m"
apt-get install -y sshpass >>/dev/null 2>>install.log
apt-get install -y snmp snmp-mibs-downloader >>/dev/null 2>>install.log


# Remove the need to user Sudo before docker. This generally requires you to log out and log back in, which is why we restart at the end of the script.
echo -e "\e[36mRemoving "Sudo" requirement from docker command \e[0m"
sudo usermod -aG docker $(logname) >>/dev/null 2>>install.log

# Restart Announcment for previous command
echo -e "\e[7mThe VM needs to be restarted in order to apply changes. \e[0m"

echo -n "Press any key to restart"
read -rsn1

# Restart
reboot
