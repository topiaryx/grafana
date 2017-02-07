#!/bin/bash
# Setup script for ESXi CPU and Memory collection.

# Determine which user is logged in
USER=$(whoami)

# Collect Information

echo -n "Welcome to the installation script for ESXi CPU and Memory collection. This script will ask for some data and create all the necessary files to get you up and running!"

echo
echo

echo -n "Press any key to continue"
read -rsn1

echo
echo

echo -n "Where would you like the script and config files place? Please us the full path. Example: /home/$USER/scripts/esxi/ = "
read DIR

echo

echo -n "What is the name of your ESXi host? This will be whatever you want it to appear as in Grafana = "
read HOST

echo

echo -n "What is the ip of your ESXi host? = "
read ESXIP

echo

echo -n "What is the root username for your ESXi host? = "
read ROOT

echo

echo -n "What is the root password for your ESXi host? = "
read -s PASSWORD

echo
echo

echo -n "What is the IP of your InfluxDB? Make sure to include your port. The default port of InfluxDB is 8086. Example: 10.10.10.100:8086  = "
read INFLUXIP

echo

echo -n "What is the name of the database you'd like your stats saved in? If the database does not exist, it will be automatically created. = "
read DATABASE

echo

echo -n "How often would you like the script to poll your ESXi host? (In seconds) = "
read INTERVAL



# Ensure directory exists
echo -e "\e[36mVerifying Directory Status \e[0m"

if [ ! -d "$DIR" ]; then
  mkdir -p "$DIR"
fi >/dev/null 2>&1



# Create ESXi config file
echo -e "\e[36mCreating Configuration File \e[0m"


cat >$DIR"esxi.cfg"<<EOF >/dev/null 2>&1
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
USERNAME=${ROOT}

# ESXI Root Password
PASSWORD=${PASSWORD}

# InfluxDB IP
INFLUXIP=${INFLUXIP}

# Name of Database
DATABASE=${DATABASE}

# Interval between polls (In seconds)
INTERVAL=${INTERVAL}

EOF

# Download ESXi.sh
cho -e "\e[36mDownloading ESXi script file. \e[0m"
wget -O $DIR"esxi.sh" https://raw.githubusercontent.com/tylerhammer/grafana/master/Data%20Collection/ESXi/esxi.sh >/dev/null 2>&1

# Update ESXi.sh with config file.
echo -e "\e[36mConnecting Configuration file and ESXi script. \e[0m"
sed -i "10i . "$DIR"esxi.cfg" $DIR"esxi.sh" >/dev/null 2>&1

# Set Chmod
echo -e "\e[36mUpdating permissions. \e[0m"
chmod +x $DIR"esxi.sh"

# Create DATABASE
echo -e "\e[36mCreating database in InfluxDB. \e[0m"
curl -i -XPOST "http://$INFLUXIP/query" --data-urlencode "q=CREATE DATABASE $DATABASE" >/dev/null 2>&1

# Create SystemD file
echo -e "\e[36mCreating SystemD file.\e[0m"
sudo bash -c "cat >/lib/systemd/system/esximon.service" << EOF >/dev/null 2>&1
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

# Enable SystemD service
echo -e "\e[36mEnabling Services \e[0m"
systemctl enable esximon.service >/dev/null 2>&1
systemctl start esximon.service >/dev/null 2>&1


# Finishing thoughts
echo "Congradulations, the ESXi setup script has successfully completed and you should start seeing data in Influx."
echo "If you're running into an issue where you're getting a missing feild value error, please check out cyanlab.io for a posted fix."
echo "Should you have any other questions or suggestions, please reach out to me at git@tylerhammer.com or on Discord Hammer#4341."
