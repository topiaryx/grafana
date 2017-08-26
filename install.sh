#!/bin/bash
# This script will install Docker, Grafana, InfluxDB, Graphite & CollectD. It will also add systemd service files to ensure auto startup each boot.
# This script was originally created by reddit user /u/tyler_hammer and was modified by reddit user /u/topiaryx to work on CentOS 7.
# This is a combination of several guides with edits to make it as easy as possible for new people to start.

# Checking for Root Permissions # Thanks to Github User "codygarver" for the recommendation
check_your_privilege () {
    if [[ "$(id -u)" != 0 ]]; then
        echo -e "\e[91mError: This setup script requires root permissions. Please run the script as root.\e[0m" > /dev/stderr
        exit 1
    fi
}
check_your_privilege

#
# Docker installation for CentOS 7+
#

clear

# Grab machine IP for link
my_ip=$(ip route | head -n 1 | egrep 'dev (.*)' -o | cut -d' ' -f2 | xargs ip a s $1 | egrep '([0-9]{1,3}\.){3}[0-9]{1,3}' -o | awk '{ if (NR == 1) print $1}')

# Update package database and system (installs EPEL)
while true; do
	echo -n -e "\e[7mDo you wish to run system updates? [y/n]:\e[0m "
	read yn
	case $yn in
		[yY] | [yY] | [yY][Ee][Ss] ) echo -ne "\e[36mUpdating System - This will take a long time, be patient!\e[0m"; yum install -y epel-release >/dev/null 2>>install.log && yum update -y >/dev/null 2>>install.log && yum upgrade -y >/dev/null 2>>install.log; clear; echo -e "\r\033[K\e[36mUpdating System ----- Complete\e[0m"; break;; #(Run both in one line)
		[nN] | [n|N][O|o] ) echo -e "\e[36mSkipping Updates\e[0m"; break;;  #Boring people don't update																							
		* ) echo -e "\e[7mPlease answer y or n.\e[0m ";;  #Error handling to get the right answer
    esac
done

echo

## Add Docker CentOS Repo and Prereq's
echo -ne "\e[36mInstalling Docker Repo\e[0m"
yum install -y yum-utils device-mapper-persistent-data lvm2 >>/dev/null 2>>install.log
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo -y >>/dev/null 2>>install.log

# Update Database
echo -ne "\e[36mUpdating Database\e[0m"
yum update >>/dev/null 2>>install.log
echo -e "\r\033[K\e[36mUpdating Database ----- Complete\e[0m"

# Verify Repo
echo -ne "\e[36mVerifying Repo\e[0m"
yum makecache fast >>/dev/null 2>>install.log
echo -e "\r\033[K\e[36mVerifying Repo ----- Complete\e[0m"

# Install Docker
echo -ne "\e[36mInstalling Docker-CE\e[0m"
yum install -y docker-ce >>/dev/null 2>>install.log
echo -e "\r\033[K\e[36mInstalling Docker-CE ----- Complete\e[0m"

# Start Docker
echo -ne "\e[36mStarting Docker\e[0m"
systemctl start docker
echo -e "\r\033[K\e[36mStarting Docker ----- Complete\e[0m"

# Enable Docker
echo -ne "\e[36mEnabling Docker\e[0m"
echo
systemctl enable docker
echo -e "\r\033[K\e[36mEnabling Docker ----- Complete\e[0m"

#
# Grafana Install
#

echo -e "\e[7mPlease specify an admin password for Grafana\e[0m"
read -p "> " -s GADMINPW

echo
echo

echo -e "\e[7mPlease re-enter the password\e[0m"
read -p "> " -s GADMINPW2

echo
echo

# Make sure passwords are the same before continuing
while [ "${GADMINPW}" != "${GADMINPW2}" ];
do
 echo
 echo -e "\e[41mPasswords do not match, please try again!\e[0m"
 echo
 echo -e "\e[7mPlease specify an admin password for Grafana\e[0m"
 read -p "> " -s GADMINPW
 echo
 echo
 echo -e "\e[7mPlease re-enter the password\e[0m"
 read -p "> " -s GADMINPW2
 echo
done

clear
echo -e "\r\033[K\e[36mUpdating System ----- Complete\e[0m"
echo -e "\r\033[K\e[36mInstalling Docker Repo ----- Complete\e[0m"
echo -e "\r\033[K\e[36mUpdating Database ----- Complete\e[0m"
echo -e "\r\033[K\e[36mVerifying Repo ----- Complete\e[0m"
echo -e "\r\033[K\e[36mInstalling Docker ----- Complete\e[0m"
echo -e "\r\033[K\e[36mStarting Docker ----- Complete\e[0m"
echo -e "\r\033[K\e[36mEnabling Docker ----- Complete\e[0m"

# Create Persistent Storage
echo -ne "\e[36mCreating persistent storage for Grafana\e[0m"
docker run -d -v /var/lib/grafana --name grafana-storage busybox:latest >>/dev/null 2>>install.log
echo -e "\r\033[K\e[36mCreating persistent storage for Grafana ----- Complete\e[0m"

# Create Grafana Docker
echo -ne "\e[36mCreating Grafana docker container - This make take awhile!\e[0m"
sudo docker create \
--name=grafana \
--restart always \
-p 3000:3000 \
--volumes-from grafana-storage \
-e "GF_SECURITY_ADMIN_PASSWORD=${GADMINPW}" \
grafana/grafana >>/dev/null 2>>install.log
echo -e "\r\033[K\e[36mCreating Grafana docker container ----- Complete\e[0m"

# Start Grafana Docker
echo -ne "\e[36mStarting Grafana\e[0m"
docker start grafana >>/dev/null 2>>install.log
echo -e "\r\033[K\e[36mStarting Grafana ----- Complete\e[0m"

# Make Bin folder for update scripts
echo -ne "\e[36mCreating Update Folder\e[0m"
mkdir ~/updates >>/dev/null 2>>install.log
echo -e "\r\033[K\e[36mCreating Update Folder ----- Complete\e[0m"

# Download Grafana Update Script
echo -ne "\e[36mDownloading Grafana update script\e[0m"
wget https://raw.githubusercontent.com/topiaryx/grafana/master/Update%20Scripts/grafanaupdate.sh -O ~/updates/updategrafana.sh >>/dev/null 2>>install.log
echo -e "\r\033[K\e[36mDownloading Grafana update script ----- Complete\e[0m"

#
# InfluxDB Install
#

# Create Local Storage
echo -ne "\e[36mCreating local storage for InfluxDB\e[0m"
mkdir -p /docker/containers/influxdb/conf/ >>/dev/null 2>>install.log
mkdir -p /docker/containers/influxdb/db/ >>/dev/null 2>>install.log
echo -e "\r\033[K\e[36mCreating local storage for InfluxDB ----- Complete\e[0m"

# Check Ownership
echo -ne "\e[36mVerifying ownership\e[0m"
chown ${USER:=$(/usr/bin/id -run)}:${USER} -R /docker >>/dev/null 2>>install.log
echo -e "\r\033[K\e[36mVerifying ownership ----- Complete\e[0m"

# Generate Default Config
echo -ne "\e[36mGenerating default config file for InfluxDB\e[0m"
docker run --rm influxdb influxd config > /docker/containers/influxdb/conf/influxdb.conf 2>>install.log
echo -e "\r\033[K\e[36mGenerating default config file for InfluxDB ----- Complete\e[0m"

# Create InfluxDB Container
echo -ne "\e[36mCreating InfluxDB docker container - This make take awhile!\e[0m"
docker create \
--name influxdb \
--restart always \
-e PUID=1000 -e PGID=1000 \
-p 8083:8083 -p 8086:8086 \
-v /docker/containers/influxdb/conf/influxdb.conf:/etc/influxdb/influxdb.conf:ro \
-v /docker/containers/influxdb/db:/var/lib/influxdb \
influxdb -config /etc/influxdb/influxdb.conf >>/dev/null 2>>install.log
echo -e "\r\033[K\e[36mCreating InfluxDB docker container ----- Complete\e[0m"

# Start InfluxDB
echo -ne "\e[36mStarting InfluxDB\e[0m"
docker start influxdb >>/dev/null 2>>install.log
echo -e "\r\033[K\e[36mStarting InfluxDB ----- Complete\e[0m"

# Create Influx Update Script
echo -ne "\e[36mDownloading InfluxDB update script\e[0m"
wget https://raw.githubusercontent.com/topiaryx/grafana/master/Update%20Scripts/influxdbupdate.sh -O ~/updates/influxupdate.sh >>/dev/null 2>>install.log
echo -e "\r\033[K\e[36mDownloading InfluxDB update script ----- Complete\e[0m"

#
# Graphite Install - Removed InfluxDB WebUI code
#

# Create Graphite Container
echo -ne "\e[36mCreating Graphite docker container - This may take awhile!\e[0m"
docker run -d\
 --name graphite\
 --restart always \
 -p 80:80\
 -p 2003-2004:2003-2004\
 -p 2023-2024:2023-2024\
 -p 8125:8125/udp\
 -p 8126:8126\
 hopsoft/graphite-statsd >>/dev/null 2>>install.log
echo -e "\r\033[K\e[36mCreating Graphite docker container ----- Complete\e[0m"

# Install other dependencies
echo -ne "\e[36mInstalling SSHPASS and SNMP dependencies - This may take awhile!\e[0m"
yum install -y sshpass >>/dev/null 2>>install.log
yum install net-snmp net-snmp-utils net-snmp-devel >>/dev/null 2>>install.log
echo -e "\r\033[K\e[36mInstalling SSHPASS and SNMP dependencies ----- Complete\e[0m"

# Remove the need to user Sudo before docker. This generally requires you to log out and log back in, which is why we restart at the end of the script.
echo -ne "\e[36mRemoving "Sudo" requirement from docker command\e[0m"
sudo usermod -aG docker $(logname) >>/dev/null 2>>install.log
echo -e "\r\033[K\e[36mRemoving "Sudo" requirement from docker command ----- Complete\e[0m"

# Restart Announcment for previous command
echo -e "\e[7mThe VM needs to be restarted in order to apply changes and finalize the installation.\e[0m"

echo -e "\e[7mAfter the restart, Grafana can be accessed via http://${my_ip}:3000 with the user "Root" and the password you created earlier in the installation.\e[0m"

echo -n "Press any key to restart"
read -rsn1

# Restart
reboot
