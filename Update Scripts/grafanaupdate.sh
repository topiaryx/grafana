#!/bin/bash
# Define a timestamp function
timestamp() {
  date +"%Y-%m-%d_%H-%M-%S"
}
timestamp
echo -ne "\e[36mPulling latest from grafana/grafana\e[0m"
docker pull grafana/grafana >>/dev/null 2>>grafana_update.log
echo -e "\r\033[K\e[36mPulling latest from grafana/grafana ----- Complete\e[0m"

echo -ne "\e[36mStopping Grafana\e[0m"
docker stop grafana
echo -e "\r\033[K\e[36mStopping Grafana ----- Complete\e[0m"

echo -ne "\e[36mBacking up old Grafana container to grafana_$(timestamp)\e[0m"
docker rename grafana grafana_$(timestamp)
echo -e "\r\033[K\e[36mBacking up old Grafana container to grafana_$(timestamp) ----- Complete\e[0m"

clear

# Grafana Update - Docker - Ubuntu 16.04

echo -e "\e[7mPlease specify an admin password for Grafana\e[0m"
read -p "> " -s GADMINPW

echo
echo

echo -e "\e[7mPlease re-enter the password\e[0m"
read -p "> " -s GADMINPW2

echo
echo

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
echo -ne "\e[36mCreating Grafana docker container - This make take awhile!\e[0m"
sudo docker create \
--name=grafana \
--restart always \
-p 3000:3000 \
--volumes-from grafana-storage \
-e "GF_SECURITY_ADMIN_PASSWORD=${GADMINPW}" \
grafana/grafana >>/dev/null 2>>grafana_update.log
echo -e "\r\033[K\e[36mCreating Grafana docker container ----- Complete\e[0m"

echo -ne "\e[36mStarting Grafana container!\e[0m"
docker start grafana >>/dev/null 2>>grafana_update.log
echo -e "\r\033[K\e[36mStarting Grafana container ----- Complete\e[0m"