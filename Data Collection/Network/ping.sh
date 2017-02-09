#!/bin/bash

# Config File Location
. ping.cfg

#Prepare to start the loop and warn the user
echo "Press [CTRL+C] to stop..."
while :
do

	#Lets ping the host!
	results=$(ping -c $PINGS -i $WAIT -q $HOST)

	#We need to get ONLY lines 4 and 5 from the results
	#The rest isn't needed for ourpurposes
	counter=0
	while read -r line; do
		((counter++))
		if [ $counter = 4 ]
		then
			line4="$line"
		fi
		if [ $counter = 5 ]
		then
			line5="$line"
		fi
	done <<< "$results"

	echo "$line4"
	echo "$line5"

	#Parse out the 2 lines
	#First we need to get the packet loss
	IFS=',' read -ra arrline4 <<< "$line4" #Split the line based on a ,
	loss=${arrline4[2]} #Get just the 3rd element containing the loss
	IFS='%' read -ra lossnumber <<< "$loss" #Split the thrid element based on a %
	lossnumber=$(echo $lossnumber | xargs) #Remove the leading whitespace

	#Now lets get the min/avg/max/mdev
	IFS=' = ' read -ra arrline5 <<< "$line5" #Split the lines based on a =
	numbers=${arrline5[2]} #Get the right side containing the actual numbers
	IFS='/' read -ra numbersarray <<< "$numbers" #Break out all the numbers based on a /
	#Get the individual values from the array
	min=${numbersarray[0]}
	avg=${numbersarray[1]}
	max=${numbersarray[2]}
	mdev=${numbersarray[3]}

	#Write the data to the database
	curl -i -XPOST "http://$INFLUXIP/write?db=$DATABASE" --data-binary "ping,host=$HOST,measurement=loss value=$lossnumber"
	curl -i -XPOST "http://$INFLUXIP/write?db=$DATABASE" --data-binary "ping,host=$HOST,measurement=min value=$min"
	curl -i -XPOST "http://$INFLUXIP/write?db=$DATABASE" --data-binary "ping,host=$HOST,measurement=avg value=$avg"
	curl -i -XPOST "http://$INFLUXIP/write?db=$DATABASE" --data-binary "ping,host=$HOST,measurement=max value=$max"
	curl -i -XPOST "http://$INFLUXIP/write?db=$DATABASE" --data-binary "ping,host=$HOST,measurement=mdev value=$mdev"

	#Wait for a bit before checking again
	sleep "$INTERVAL"
	
done
