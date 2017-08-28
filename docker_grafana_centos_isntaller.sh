#!/bin/bash

# This script will install Docker, Grafana, InfluxDB and Graphite. It will also add systemd service files to ensure auto startup each boot.
# This script was inspired by reddit users /u/tyler_hammer and /u/dencur. This is a combination of several guides and scripts (with edits) to make it as easy as possible to get Grafana up and running.
# Please note this script is intented to be run on a VM, however it should work on a physical machine as well.

# DCGi Version 0.1

###
### FUNCTIONS
###

# Function that checks if the user is root or has root permissions.
root_checker () {
	if [[ $EUID != 0 ]]; then
		echo -e "\e[91mError: This setup script requires root permissions. Please run the script as root.\e[0m" > /dev/stderr;
		exit 1;
	fi
}

root_checker

# Check maching IP address
ip_checker () {
	machine_ip = $(ip route get 1 | awk '{print $NF;exit}');
}

check_ownership () {
	
	chown ${USER:=$(/usr/bin/id -run)}:${USER} -R /docker > /dev/null 2>&1 >> dgc_install.log;
	echo -e "\r\033[K\e[36mVerifying ownership ----- Complete\e[0m"
}

# Prerequisite package installer
prereq_installer () {
	yum install -y epel-release && yum update -y ;
	yum install -y yum-utils evice-mapper-persistent-data lvm2 sshpass net-snmp net-snmp-devel.x86_64 net-snmp-utils.x86_64;
	clear;
}

# Docker best practice, remove old Docker installations before installing an updated version
remove_old_docker () {
	yum remove -y docker docker-common docker-selinux docker-engine; 
	clear;
}

# Add Docker repository
add_docker_repo () {
	yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo;
	clear;
}

# Docker Install, run and test
docker_installer () {
	yum makecache fast && yum install -y docker-ce;
	systemctl start docker;
	systemctl enable docker;
	clear;
}

# Verify Docker is working
verify_docker () {
	docker run hello-world;
	docker ps -a | grep -i "hello-world" | gawk '{print $1}' | xargs docker rm;
	docker rmi -f hello-world;
	clear;
}

get_grafana_admin_pw() {
	echo -e "\e[7mPlease specify an admin password for Grafana\e[0m";
	read -p "> " -s GADMINPW;
	echo
	echo
	
	echo -e "\e[7mPlease re-enter the password\e[0m";
	read -p "> " -s GADMINPW2;
	echo
	echo

	while [ "${GADMINPW}" != "${GADMINPW2}" ];
		do
 			echo
 			echo -e "\e[41mPasswords do not match, please try again!\e[0m";
 			echo
 			
 			echo -e "\e[7mPlease specify an admin password for Grafana\e[0m";
 			read -p "> " -s GADMINPW;
			echo
 			echo
 			
 			echo -e "\e[7mPlease re-enter the password\e[0m";
            read -p "> " -s GADMINPW2;
 			echo
 			echo
	done
}

create_grafana_persistent_storage () {
	docker run -d -v /var/lib/grafana --name grafana-storage busybox:latest > /dev/null 2>&1 >> dgc_install.log;
}

create_grafana_container () {
	docker create --name=grafana --restart always -p 3000:3000 --volumes-from grafana-storage -e \
	"GF_SECURITY_ADMIN_PASSWORD=${GADMINPW}" grafana/grafana > /dev/null 2>&1 >> dgc_install.log;
}

start_grafana () {
	docker start grafana > /dev/null 2>&1 >> dgc_install.log;
}

make_update_script_folder () {
	mkdir ~/updates > /dev/null 2>&1 >> dgc_install.log;
}

download_grafana_update_scripts () {
	wget https://raw.githubusercontent.com/topiaryx/grafana/master/Update%20Scripts/grafanaupdate.sh -O ~/updates/updategrafana.sh > /dev/null 2>&1 >> dgc_install.log;
}

create_influxdb_persistent_storage () {
	echo -ne "\e[36mCreating local storage for InfluxDB\e[0m";
	mkdir -p /docker/containers/influxdb/conf/ > /dev/null 2>&1 >> dgc_install.log;
	mkdir -p /docker/containers/influxdb/db/ > /dev/null 2>&1 >> dgc_install.log;
	echo -e "\r\033[K\e[36mCreating local storage for InfluxDB ----- Complete\e[0m";
}

influxdb_generate_default_config () {
	echo -ne "\e[36mGenerating default config file for InfluxDB\e[0m";
	docker run --rm influxdb influxd config > /docker/containers/influxdb/conf/influxdb.conf 2>>install.log
	echo -e "\r\033[K\e[36mGenerating default config file for InfluxDB ----- Complete\e[0m";
}

create_influxdb_container () {
	docker create --name influxdb --restart always \
		-e PUID=1000 -e PGID=1000 \
		-p 8083:8083 -p 8086:8086 \
		-v /docker/containers/influxdb/conf/influxdb.conf:/etc/influxdb/influxdb.conf:ro \
		-v /docker/containers/influxdb/db:/var/lib/influxdb \
		influxdb -config /etc/influxdb/influxdb.conf > /dev/null 2>&1 >> dgc_install.log;
}

start_influxdb () {
	echo -ne "\e[36mStarting InfluxDB\e[0m";
	docker start influxdb > /dev/null 2>&1 >> dgc_install.log;
	echo -e "\r\033[K\e[36mStarting InfluxDB ----- Complete\e[0m";
}

download_influxdb_update_script () {
	echo -ne "\e[36mDownloading InfluxDB update script\e[0m";
	wget https://raw.githubusercontent.com/topiaryx/grafana/master/Update%20Scripts/influxdbupdate.sh -O ~/updates/influxupdate.sh > /dev/null 2>&1 >> dgc_install.log;

	echo -e "\r\033[K\e[36mDownloading InfluxDB update script ----- Complete\e[0m";
}

create_gaphite_container () {
	echo -ne "\e[36mCreating Graphite docker container - This may take awhile!\e[0m";
	docker run -d \
	--name graphite \
	--restart always \
	-p 80:80 \
 	-p 2003-2004:2003-2004 \
 	-p 2023-2024:2023-2024 \
 	-p 8125:8125/udp \
 	-p 8126:8126 \
 	hopsoft/graphite-statsd > /dev/null 2>&1 >> dgc_install.log;
	echo -e "\r\033[K\e[36mCreating Graphite docker container ----- Complete\e[0m";
}

docker_group_add () {
	# Remove the need to user Sudo before docker. This generally requires you to log out and log back in, which is why we restart at the end of the script.
	echo -e "\e[36mRemoving "Sudo" requirement from docker command\e[0m";
	usermod -aG docker $(logname) > /dev/null 2>&1 >> dgc_install.log;
	echo -e "\r\033[K\e[36mRemoving 'sudo' requirement from docker command ----- Complete\e[0m";
}

# Install Docker!
install_docker () {
	# FIRE THE LAZAAAAAAAAA
	clear;
	echo -e "\e[36mPHASE 1: Installing prequisite packages";
	prereq_installer > /dev/null 2>&1 >> dgc_install.log;
	clear; 

	echo -e "\e[36mPHASE 1: Installing prequisite packages --------------------- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 1: Removing old docker installations (if present)"
	remove_old_docker > /dev/null 2>&1 >> dgc_install.log;
	clear; 

	echo -e "\e[36mPHASE 1: Installing prequisite packages --------------------- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 1: Removing old docker installations (if present) ----- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 1: Adding Docker Repository"
	add_docker_repo > /dev/null 2>&1 >> dgc_install.log;
	clear; 

	echo -e "\e[36mPHASE 1: Installing prequisite packages --------------------- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 1: Removing old docker installations (if present) ----- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 1: Adding Docker Repository --------------------------- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 1: Installing Docker"
	docker_installer > /dev/null 2>&1 >> dgc_install.log;
	clear; 

	echo -e "\e[36mPHASE 1: Installing prequisite packages --------------------- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 1: Removing old docker installations (if present) ----- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 1: Adding Docker Repository --------------------------- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 1: Installing Docker ---------------------------------- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 1: Verifying Docker"
	verify_docker > /dev/null 2>&1 >> dgc_install.log;
	clear; 

	echo -e ": Installing prequisite packages --------------------- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 1: Removing old docker installations (if present) ----- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 1: Adding Docker Repository --------------------------- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 1: Installing Docker ---------------------------------- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 1: Verifying Docker ----------------------------------- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 1: COMPLETE\e[0m";
	echo
}

install_grafana() {
	echo -e "\e[36mPHASE 1: COMPLETE\e[0m";
	echo
	echo -e "\e[36mPHASE 2: Creating persistent storage for Grafana\e[0m";
	create_grafana_persistent_storage;
	clear;

	echo -e "\e[36mPHASE 1: COMPLETE\e[0m";
	echo
	echo -e "\e[36mPHASE 2: Creating persistent storage for Grafana ------ COMPLETE\e[0m";
	echo -ne "\e[36mPHASE 2: Checking ownership\e[0m";
	check_ownership;
	clear;

	echo -e "\e[36mPHASE 1: COMPLETE\e[0m";
	echo
	echo -e "\e[36mPHASE 2: Creating persistent storage for Grafana ------ COMPLETE\e[0m";
	echo -e "\e[36mPHASE 2: Checking ownership --------------------------- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 2: Creating Grafana docker container\e[0m";
	create_grafana_container;
	clear;

	echo -e "\e[36mPHASE 1: COMPLETE\e[0m";
	echo
	echo -e "\e[36mPHASE 2: Creating persistent storage for Grafana ------ COMPLETE\e[0m";
	echo -e "\e[36mPHASE 2: Checking ownership --------------------------- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 2: Creating Grafana docker container ------------ COMPLETE\e[0m";
	echo -e "\e[36mPHASE 2: Starting Grafana\e[0m";
	start_grafana;
	clear;

	echo -e "\e[36mPHASE 1: COMPLETE\e[0m";
	echo
	echo -e "\e[36mPHASE 2: Creating persistent storage for Grafana ------ COMPLETE\e[0m";
	echo -e "\e[36mPHASE 2: Checking ownership --------------------------- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 2: Creating Grafana docker container ------------ COMPLETE\e[0m";
	echo -e "\e[36mPHASE 2: Starting Grafana ----------------------------- COMPLETE\e[0m";	
	echo -e "\e[36mPHASE 2: Creating Update Folder\e[0m";
	make_update_script_folder;
	clear;
	
	echo -e "\e[36mPHASE 1: COMPLETE"
	echo
	echo -e "\e[36mPHASE 2: Creating persistent storage for Grafana ------ COMPLETE\e[0m";
	echo -e "\e[36mPHASE 2: Checking ownership --------------------------- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 2: Creating Grafana docker container ------------ COMPLETE\e[0m";
	echo -e "\e[36mPHASE 2: Starting Grafana ----------------------------- COMPLETE\e[0m";	
	echo -e "\e[36mPHASE 2: Creating Update Folder ----------------------- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 2: Downloading Grafana update script\e[0m";
	download_grafana_update_scripts;
	clear;
	
	echo -e "\e[36mPHASE 1: COMPLETE"
	echo
	echo -e "\e[36mPHASE 2: Creating persistent storage for Grafana ------ COMPLETE\e[0m";
	echo -e "\e[36mPHASE 2: Checking ownership --------------------------- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 2: Creating Grafana docker container ------------ COMPLETE\e[0m";
	echo -e "\e[36mPHASE 2: Starting Grafana ----------------------------- COMPLETE\e[0m";	
	echo -e "\e[36mPHASE 2: Creating Update Folder ----------------------- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 2: Downloading Grafana update script ------------ COMPLETE\e[0m";
	echo -e "PHASE 2: COMPLETE"
}

install_influxdb () {
	echo -e "\e[36mPHASE 1: COMPLETE\e[0m";
	echo -e "PHASE 2: COMPLETE\e[0m";
	echo
	echo -e "\e[36mPHASE 3: Creating InfluxDB docker container\e[0m";
	create_influxdb_persistent_storage;
	clear;

	echo -e "\e[36mPHASE 1: COMPLETE\e[0m";
	echo -e "PHASE 2: COMPLETE\e[0m";
	echo
	echo -e "\e[36mPHASE 3: Creating InfluxDB docker container ----------- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 2: Checking ownership"
	check_ownership;
	clear;

	echo -e "\e[36mPHASE 1: COMPLETE\e[0m";
	echo -e "PHASE 2: COMPLETE\e[0m";
	echo
	echo -e "\e[36mPHASE 3: Creating InfluxDB docker container ----------- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 2: Checking ownership --------------------------- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 2: Generating default InfluxDB configuration";
	influxdb_generate_default_config;
	clear;

	echo -e "\e[36mPHASE 1: COMPLETE\e[0m";
	echo -e "PHASE 2: COMPLETE\e[0m";
	echo
	echo -e "\e[36mPHASE 3: Creating InfluxDB docker container ----------- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 3: Checking ownership --------------------------- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 3: Generating default InfluxDB configuration ---- COMPLETE\e[0m";
	create_influxdb_container;
	clear;

	echo -e "\e[36mPHASE 1: COMPLETE\e[0m";
	echo -e "PHASE 2: COMPLETE\e[0m";
	echo
	echo -e "\e[36mPHASE 3: Creating InfluxDB docker container ----------- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 3: Checking ownership --------------------------- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 3: Generating default InfluxDB configuration ---- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 3: Starting InfluxDB";
	start_influxdb;
	clear;

	echo -e "\e[36mPHASE 1: COMPLETE\e[0m";
	echo -e "\e[36mPHASE 2: COMPLETE\e[0m";
	echo
	echo -e "\e[36mPHASE 3: Creating InfluxDB docker container ----------- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 3: Checking ownership --------------------------- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 3: Generating default InfluxDB configuration ---- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 3: Starting InfluxDB ---------------------------- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 2: Downloading Grafana update script\e[0m";
	download_influxdb_update_script;
	clear;

	echo -e "\e[36mPHASE 1: COMPLETE\e[0m";
	echo -e "\e[36mPHASE 2: COMPLETE\e[0m";
	echo
	echo -e "\e[36mPHASE 3: Creating InfluxDB docker container ----------- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 3: Checking ownership --------------------------- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 3: Generating default InfluxDB configuration ---- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 3: Starting InfluxDB ---------------------------- COMPLETE\e[0m";
	echo -e "\e[36mPHASE 2: Downloading Grafana update script ------------ COMPLETE\e[0m";
	echo -e "\e[36mPHASE 3: COMPLETE\e[0m";
}

install_graphite () {
	echo -e "\e[36mPHASE 1: COMPLETE\e[0m";
	echo -e "\e[36mPHASE 2: COMPLETE\e[0m";
	echo -e "\e[36mPHASE 3: COMPLETE\e[0m";
	echo
	echo -e "\e[36mPHASE 3: Creating Graphite docker container";
	create_gaphite_container;
	clear;

	echo -e "\e[36mPHASE 1: COMPLETE\e[0m";
	echo -e "\e[36mPHASE 2: COMPLETE\e[0m";
	echo -e "\e[36mPHASE 3: COMPLETE\e[0m";
	echo -e "\e[36mPHASE 4: COMPLETE\e[0m";
}

###
### EXECUTE
###

clear;

ip_checker

while true; do
    echo -n -e "\e[7mDo you want to update your system? [y/n]:\e[0m ";
    read onsey;
    case $onsey in
        [yY] ) 
			echo -e "Updating system!" && yum update -y && yum upgrade -y && install_docker && install_grafana && install_graphite && install_influxdb && docker_group_add; break;; # Update, upgrade and install
        [nN] ) 
			echo -e "\e[36mSkipping Updates\e[0m"; install_docker && install_grafana && install_graphite && install_influxdb && docker_group_add; break;; # Skip updates and install
        * ) 
        	echo -e "\e[7mPlease answer 'y' or 'n'\e[0m ";; # Error handling to get the right answer
    esac
done

# Restart announcement
echo
echo -e "\e[7mThe VM needs to be restarted in order to apply changes and finalize the installation.\e[0m";
echo -e "\e[7mAfter the restart, Grafana can be accessed via http://${machine_ip}:3000 with the user 'admin' and the password you created earlier in the installation.\e[0m";
echo -n "Press any key to restart...";
read -rsn1;

# Restart
reboot;