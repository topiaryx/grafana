#!/bin/bash
# This script is designed to download and setup the PlexMon serviec for Grafana.
# Actual scripts were coded by /u/BarryCarey. https://github.com/barrycarey/Plex-Data-Collector-For-InfluxDB
USER=$(logname)

clear
# Gather information
echo -e "\e[7mWelcome to the PlexMon setup script. This script is will ask you a couple of questions and then we'll be under way!\e[0m"
echo -e "\e[7mThis Script requires Python3, Pip3, and a couple of Python dependencies. Those will be installed during the installation process.\e[0m"

echo
echo

echo -ne "\e[7mPress any key to continue\e[0m"
read -rsn1

clear

echo -e "\e[7mWhat is the IP Address of your InfluxDB Server? (Do not include the port)\e[0m"
read -p "> " INFLUXDBIP

echo

echo -e "\e[7mWhat port do you use for InfluxDB? (The default port is 8086)\e[0m"
read -p "> " INFLUXDBPORT

echo

echo -e "\e[7mWhat is the name of the database you'd like to use? (If the database does not exist, it will be created)\e[0m"
read -p "> " DATABASE

echo

echo -e "\e[7mWhat is your Plex username?\e[0m"
read -p "> " PLEXUN

echo

echo -e "\e[7mWhat is your Plex password?\e[0m"
read -p "> " -s PLEXPW

echo
echo

echo -e "\e[7mWhat is the IP address of your Plex Server? (Do not include the port)\e[0m"
read -p "> " PLEXSERVER

echo

echo -e "\e[7mWhat directory would you like these files to be saved? (Example /home/$USER/scripts/plex/)\e[0m"
read -p "> " DIR

clear

# Ensure directory exists
echo -ne "\e[36mVerifying Directory Status \e[0m"
if [ ! -d "${DIR}" ]; then
  mkdir -p "${DIR}"
fi >/dev/null 2>plexmon_setup.log
echo -e "\r\033[K\e[36mVerifying Directory Status ----- Complete\e[0m"

# Install Python3
echo -ne "\e[36mChecking for Python3\e[0m"
if [ $(dpkg-query -W -f='${Status}' python3 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  sudo apt-get install -y python3 >/dev/null 2>>plexmon_setup.log;
fi
echo -e "\r\033[K\e[36mChecking for Python3 ----- Complete"

# Install Python3-pip
echo -ne "\e[36mChecking for Python3-pip\e[0m"
if [ $(dpkg-query -W -f='${Status}' python3-pip 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  sudo apt-get install -y python3-pip >/dev/null 2>>plexmon_setup.log;
fi
echo -e "\r\033[K\e[36mChecking for Python3-pip ----- Complete"

# Install Python Dependencies
echo -ne "\e[36mDownloading Python Dependencies\e[0m"
sudo pip3 install influxdb >/dev/null 2>>plexmon_setup.log
sudo pip3 install request >/dev/null 2>>plexmon_setup.log
echo -e "\r\033[K\e[36mDownloading Python Dependencies ----- Complete\e[0m"

#Download and edit Config file
echo -ne "\e[36mCreating Config file \e[0m"
wget -O ${DIR}"config.ini" https://raw.githubusercontent.com/barrycarey/Plex-Data-Collector-For-InfluxDB/master/config.ini >/dev/null 2>>plexmon_setup.log
# Add INFFLUXDBIP
sed -i "6s/.*/Address =${INFLUXDBIP}/" ${DIR}"config.ini" >/dev/null 2>>plexmon_setup.log
# Add INFFLUXDBPORT
sed -i "7s/.*/Port = ${INFLUXDBPORT}/" ${DIR}"config.ini" >/dev/null 2>>plexmon_setup.log
# Add DATABASE
sed -i "8s/.*/Database =${DATABASE}/" ${DIR}"config.ini" >/dev/null 2>>plexmon_setup.log
# Add PLEXUN
sed -i "14s/.*/Username =${PLEXUN}/" ${DIR}"config.ini" >/dev/null 2>>plexmon_setup.log
# Add PLEXPW
sed -i "15s/.*/Password =${PLEXPW}/" ${DIR}"config.ini" >/dev/null 2>>plexmon_setup.log
# Add PLEXSERVERS
sed -i "18s/.*/Servers =${PLEXSERVER}/" ${DIR}"config.ini" >/dev/null 2>>plexmon_setup.log
# Add OUTPUT
sed -i "24s|.*|LogFile = ${DIR}output.log |" ${DIR}"config.ini" >/dev/null 2>>plexmon_setup.log
echo -e "\r\033[K\e[36mCreating Config file ----- Complete\e[0m"

# Create DATABASE
echo -ne "\e[36mCreating database in InfluxDB. \e[0m"
curl -i -XPOST "http://$INFLUXDBIP:$INFLUXDBPORT/query" --data-urlencode "q=CREATE DATABASE $DATABASE" >/dev/null 2>>plexmon_setup.log
echo -e "\r\033[K\e[36mCreating database in InfluxDB ----- Complete\e[0m"

# Download Collection Script
echo -ne "\e[36mDownloading collection script\e[0m"
wget -O ${DIR}"plexInfluxdbCollector.py" https://raw.githubusercontent.com/barrycarey/Plex-Data-Collector-For-InfluxDB/master/plexInfluxdbCollector.py >/dev/null 2>>plexmon_setup.log
echo -e "\r\033[k\e[36mDownloading collection script ----- Complete"

# Updating Collection Script
echo -ne "\e[36mUpdating collection script\e[0m"
sed -i "601s|.*|    parser.add_argument('--config', default='${DIR}config.ini', dest='config', help='Specify a custom location for the config file')|" ${DIR}"plexInfluxdbCollector.py" >/dev/null 2>>plexmon_setup.log
echo -e "\r\033[k\e[36mUpdating collection script ----- Complete"

# Create service
echo -ne "\e[36mCreating service file\e[0m"
sudo bash -c "cat >/lib/systemd/system/plexmon.service" << EOF
[Unit]
Description=Plex Monitor
Requires=influxdb.service
After=influxdb.service

[Service]
Type=idle
User=${USER}
ExecStart=/usr/bin/python3 ${DIR}plexInfluxdbCollector.py

[Install]
WantedBy=default.target
EOF
echo -e "\r\033[k\e[36mCreating service file ----- Complete\e[0m"

echo -ne "\e[36mEnabling Services\e[0m"
sudo systemctl enable plexmon.service >/dev/null 2>>plexmon_setup.log
sudo systemctl start plexmon.service >/dev/null 2>>plexmon_setup.log
echo -e "\r\033[K\e[36mEnabling Services ----- Complete\e[0m"

echo -e "\e[7mSetup has completed. Head on over to Grafana and import the dashboard example, and you're all set!\e[0m"
