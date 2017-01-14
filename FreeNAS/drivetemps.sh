#!/bin/sh

#This script requires sshpass installed
#This script requires the "FreeNAS Disk temps Final" script be placed into /root/scripts/ on FreeNAS and named hdd_temp.sh
#Don't forget to also chmod +x hdd_temp.sh

#Create a file named password where this script will run from and enter your FreeNAS root password into it, this will be
#Needed for sshpass to connect using -f password , as password is the file name

#Prepare to start the loop and warn the user
echo "Press [CTRL+C] to stop..."

while :
do
#Connect to FreeNAS
    connect=$(sshpass -f /home/hammer/scripts/password ssh -oStrictHostKeyChecking=no root@10.10.10.63 "/bin/sh /root/scripts/hdd_temp.sh" >/dev/null)
#Wait for a bit before checking again
sleep 15m
done
     