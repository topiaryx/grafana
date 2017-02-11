#!/bin/bash
# Setup script for ESXi CPU and Memory collection.

# Determine which user is logged in
USER=$(logname)

clear

# Collect Information

echo -e "\e[7mWelcome to the setup script for ESXi CPU and Memory collection. This script will ask for some data and create all the necessary files to get you up and running! \e[0m"
echo -e "\e[7mNote: Please do not run this script as sudo. Proper directory permissions should be set up prior to this script being run. If you're running it as sudo, please Control+C to exit now."

echo
echo

echo -n "Press any key to continue"
read -rsn1

echo
echo

echo -e "\e[7mWhere would you like the script and config files place? Please us the full path. (Example: /home/$USER/scripts/esxi/) \e[0m"
read -p "> " DIR

echo

echo -e "\e[7mWhat is the name of your ESXi host? This is what your host will be displayed as in Grafana. \e[0m"
read -p "> " HOST

echo

echo -e "\e[7mWhat is the IP of your ESXi host? \e[0m"
read -p "> " ESXIP

echo

echo -e "\e[7mWhat is the root username for your ESXi host? \e[0m"
read -p "> " ROOT

echo

echo -e "\e[7mWhat is the root password for your ESXi host? \e[0m"
read -p "> " -s PASSWORD

echo
echo

echo -e "\e[7mWhat is the complete IP of your InfluxDB? Must include the port. InfluxDB's default port is 8086.  (Example: 10.10.10.100:8086) \e[0m"
read -p "> " INFLUXIP

echo

echo -e "\e[7mWhat is the name of the database you'd like to use? If the database does not exist, it will be automatically created. \e[0m"
read -p "> " DATABASE

echo

echo -e "\e[7mHow often would you like the script to poll your ESXi host? (In seconds) \e[0m"
read -p "> " INTERVAL

clear

# Ensure directory exists
echo -ne "\e[36mVerifying Directory Status \e[0m"
if [ ! -d "$DIR" ]; then
  mkdir -p "$DIR"
fi >/dev/null 2>esxi_setup.log
echo -e "\r\033[K\e[36mVerifying Directory Status ----- Complete\e[0m"


# Create ESXi config file
echo -ne "\e[36mCreating Configuration File \e[0m"
cat >$DIR"esxi.cfg"<<EOF
#####################################
#                                   #
# Configuration File for ESXi.sh    #
#                                   #
# Created by github.com/tylerhammer #
#                                   #
#####################################

# Host name of ESXi
HOST=${HOST}

# ESXi Host IP
ESXIP=${ESXIP}

# ESXi Root Username
ROOT=${ROOT}

# ESXI Root Password
PASSWORD=${PASSWORD}

# InfluxDB IP
INFLUXIP=${INFLUXIP}

# Name of Database
DATABASE=${DATABASE}

# Interval between polls (In seconds)
INTERVAL=${INTERVAL}

EOF
echo -e "\r\033[K\e[36mCreating Configuration File ----- Complete\e[0m"

# Download ESXi.sh
echo -ne "\e[36mDownloading ESXi script file\e[0m"
wget -O $DIR"esxi.sh" https://raw.githubusercontent.com/tylerhammer/grafana/master/Data%20Collection/ESXi/esxi.sh >/dev/null 2>>esxi_setup.log
echo -e "\r\033[K\e[36mDownloading ESXi script file ----- Complete\e[0m"

# Update ESXi.sh with config file.
echo -ne "\e[36mConnecting Configuration file and ESXi script\e[0m"
sed -i "10i . "$DIR"esxi.cfg" $DIR"esxi.sh" >/dev/null 2>>esxi_setup.log
echo -e "\r\033[K\e[36mConnecting Configuration file and ESXi script ----- Complete\e[0m"

# Set Chmod
echo -ne "\e[36mUpdating permissions\e[0m"
chmod +x $DIR"esxi.sh"
echo -e "\r\033[K\e[36mUpdating permissions ----- Complete\e[0m"

# Create DATABASE
echo -ne "\e[36mCreating database in InfluxDB\e[0m"
curl -i -XPOST "http://$INFLUXIP/query" --data-urlencode "q=CREATE DATABASE $DATABASE" >/dev/null 2>>esxi_setup.log
echo -e "\r\033[K\e[36mCreating database in InfluxDB ----- Complete\e[0m"

# Create SystemD file
echo -ne "\e[36mCreating SystemD file.\e[0m"
sudo bash -c "cat >/lib/systemd/system/esximon.service" << EOF
[Unit]
Description=ESXi Stats
Requires=influxdb.service
After=influxdb.service

[Service]
Type=simple
User=$USER
ExecStart=/bin/bash -x $DIR"esxi.sh"

[Install]
WantedBy=default.target
EOF
echo -e "\r\033[K\e[36mCreating SystemD file ----- Complete\e[0m"

# Enable SystemD service
echo -ne "\e[36mEnabling Services\e[0m"
sudo systemctl enable esximon.service >/dev/null 2>>esxi_setup.log
sudo systemctl start esximon.service >/dev/null 2>>esxi_setup.log
echo -e "\r\033[K\e[36mEnabling Services ----- Complete\e[0m"

clear

# Finishing thoughts
echo -e "\e[7mCongradulations, the ESXi setup script has successfully completed and you should start seeing data in Influx. \e[0m"
echo -e "\e[7mIf you're running into an issue where you're getting a missing feild value error, please check out cyanlab.io for a posted fix. \e[0m"
echo -e "\e[7mShould you have any other questions or suggestions, please reach out to me at git@tylerhammer.com or on Discord Hammer#4341. \e[0m"
echo
