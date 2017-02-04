#!/bin/bash

#This script gets the stats for an ESXi Servers CPU and Memory
#It gets all CPU Cores via ssh and then passes the count to a while loop meaning no multiple lines per CPU
#Memory is collected via ESXCFG-Info --Hardware

#Modified by /u/imaspecialorder & /u/dantho & /u/DXM765 & /u/just_insane & /u/tylerhammer

#Config File Location
. esxi.cfg

#The time we are going to sleep between readings
sleeptime=$INTERVAL

#Get the Core Count via SSH
corecount=$(sshpass -p $PASSWORD ssh -oStrictHostKeyChecking=no -t $USERNAME@$ESXIP "grep -c ^processor /proc/cpuinfo" 2> /dev/null)
corecount=$(echo $corecount | sed 's/\r$//')


#Prepare to start the loop and warn the user
echo "Press [CTRL+C] to stop..."

#Set i to 0
i=0

while :
do
        CPUs=()
        while [ $i -lt $corecount ];
        do
                let i=i+1
                CPUs[$i]="$(snmpget -v 2c -c Public $ESXIP HOST-RESOURCES-MIB::hrProcessorLoad."$i" -Ov)"
                CPUs[$i]="$(echo "${CPUs["$i"]}" | cut -c 10-)"
                echo "CPU"$i": ${CPUs["$i"]}%"
                curl -i -XPOST "http://$INFLUXIP/write?db=$DATABASE" --data-binary "esxi_stats,host=$HOST,type=cpu_usage,cpu_number=$i value=${CPUs[$i]}"
        done
                i=0


        hwinfo=$(sshpass -p $PASSWORD ssh -oStrictHostKeyChecking=no -t $USERNAME@$ESXIP "esxcfg-info --hardware")

        #Lets try to find the lines we are looking for
        while read -r line; do
                #Check if we have the line we are looking for
                if [[ $line == *"Kernel Memory"* ]]
                then
                  kmemline=$line
                fi
                if [[ $line == *"-Free."* ]]
                then
                  freememline=$line
                fi
                #echo "... $line ..."
        done <<< "$hwinfo"

        #Remove the long string of .s
        kmemline=$(echo $kmemline | tr -s '[.]')
        freememline=$(echo $freememline | tr -s '[.]')

        #Lets parse out the memory values from the strings
        #First split on the only remaining . in the strings
IFS='.' read -ra kmemarr <<< "$kmemline"
        kmem=${kmemarr[1]}
        IFS='.' read -ra freememarr <<< "$freememline"
        freemem=${freememarr[1]}
        #Now break it apart on the space
		 IFS=' ' read -ra kmemarr <<< "$kmem"
        kmem=${kmemarr[0]}
        IFS=' ' read -ra freememarr <<< "$freemem"
        freemem=${freememarr[0]}

        #Now we can finally calculate used percentage
        used=$((kmem - freemem))
        used=$((used * 100))
        pcent=$((used / kmem))


        echo "Memory Used: $pcent%"


        curl -i -XPOST "http://$INFLUXIP/write?db=$DATABASE" --data-binary "esxi_stats,host=$HOST,type=memory_usage value=$pcent"

        #Wait for a bit before checking again
        sleep "$sleeptime"

done                                  
