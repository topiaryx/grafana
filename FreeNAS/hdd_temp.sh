#!/bin/sh

 ### Parameters ###

##This script MUST be placed into /root/scripts/ and named hdd_temp.sh , if the folder does not exist, CREATE IT


drives="INSERT DRIVES daX or adaX"

#The time we are going to sleep between readings
#sleeptime=900

 ###### summary ######
### Disks ###
        for drive in $drives
        do
          temp="$(smartctl -A /dev/${drive} | grep "Temperature_Celsius" | awk '{print $10}')"
          curl -i -XPOST 'http://INFLUXDB IP/write?db=home' --data-binary "health_data,host=<HOSTNAME>,sensor=$drive value=$temp"
        done

#Wait for a bit before checking again
#sleep "$sleeptime"