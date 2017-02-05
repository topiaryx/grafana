#!/bin/sh

 ### Parameters ###

##This script MUST be placed into /root/scripts/ and named hdd_temp.sh , if the folder does not exist, CREATE IT

# Configuration File Location
. hdd_temp.cfg

 ###### summary ######
### Disks ###
        for drive in $DRIVES
        do
          temp="$(smartctl -A /dev/${drive} | grep "Temperature_Celsius" | awk '{print $10}')"
          curl -i -XPOST "http://$INFLUXIP/write?db=$DATABASE" --data-binary "health_data,host=$HOST,sensor=$drive value=$temp"
        done

#Wait for a bit before checking again
#sleep "$INTERVAL"