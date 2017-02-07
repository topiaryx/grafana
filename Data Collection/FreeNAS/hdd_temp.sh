#!/bin/sh

# Configuration File Location


 ###### summary ######
### Disks ###
        for drive in $DRIVES
        do
          temp="$(smartctl -A /dev/${drive} | grep "Temperature_Celsius" | awk '{print $10}')"
          curl -i -XPOST "http://$INFLUXIP/write?db=$DATABASE" --data-binary "health_data,host=$HOST,sensor=$drive value=$temp"
        done

#Wait for a bit before checking again
#sleep "$INTERVAL"
