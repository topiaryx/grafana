#!/bin/bash

# Checking for speedtest-cli dependency and installing if missing
if [ $(dpkg-query -W -f='${Status}' speedtest-cli 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
 sudo  apt-get install -y speedtest-cli;
fi


# Config File Location
. speedtest.cfg

#Prepare to start the loop and warn the user
echo "Press [CTRL+C] to stop..."
while :
do

	#Store the speedtest results into a variable
	results=$(speedtest-cli --simple)
	
	#echo "$results"
	
	#Lets try to find the lines we are looking for
	while read -r line; do
		#Check if we have the line we are looking for
		if [[ $line == *"Ping"* ]]
		then
		  ping=$line
		fi
		if [[ $line == *"Download"* ]]
		then
		  download=$line
		fi
		if [[ $line == *"Upload"* ]]
		then
		  upload=$line
		fi
	done <<< "$results"
	
	echo "$ping"
	echo "$download"
	echo "$upload"
	
	#Break apart the results based on a space
	IFS=' ' read -ra arrping <<< "$ping"
	ping=${arrping[1]}
	IFS=' ' read -ra arrdownload <<< "$download"
	download=${arrdownload[1]}
	IFS=' ' read -ra arrupload <<< "$upload"
	upload=${arrupload[1]}
	
	#Convet to mbps
	download=`echo - | awk "{print $download * 1048576}"`
	upload=`echo - | awk "{print $upload * 1048576}"`
	#download=$((download * 1048576))
	#upload=$((upload * 1048576))
	
	echo "$ping"
	echo "$download"
	echo "$upload"
	
	#Write to the database
	curl -i -XPOST "http://$INFLUXIP/write?db=$DATABASE" --data-binary "speedtest,metric=ping value=$ping"
	curl -i -XPOST "http://$INFLUXIP/write?db=$DATABASE" --data-binary "speedtest,metric=download value=$download"
	curl -i -XPOST "http://$INFLUXIP/write?db=$DATABASE" --data-binary "speedtest,metric=upload value=$upload"

	#Wait for a bit before checking again
	sleep "$INTERVAL"
	
done