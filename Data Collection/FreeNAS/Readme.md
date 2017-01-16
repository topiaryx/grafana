# FreeNAS
Most of the stats I collect from FreeNAS are done through collectd and Graphite. Luckily for me, FreeNAS has these built in.
You'll need to have collectd and graphite installed. 

To set FreeNAS up with Graphite, you'll need to go to System > Advanced, and update the "Remote Graphite Server Hostname" to the IP address of Graphite. It does not require the port since graphite runs on port 80. 

Once thats set, you're collecting data from FreeNAS. A lot of stats can be collected by importing the FreeNASUsage.json as a grafana dashboard.

# FreeNAS Drive Health

I am unaware of the origianl creator of these scripts. If you know, please let me know so I can update and give proper credit.   

This script is a two part script, with one portion of the script running on FreeNAS, and the other on your Grafana box.   

# HDD_Temp.sh
This script will go on your FreeNAS box. It needs to be placed in /root/scripts/ and must be named hdd_temp.sh . If this folder does not already exist, create it.   
In the script, you will need to edit 
```
drives="INSERT DRIVES daX or adaX"
```
You must list every drive you wish for it to check. I.E. "da0 da1 da2 da3" etc etc. 

You must also update the InfluxDB IP and database name if you so choose.
```
curl -i -XPOST 'http://INFLUXDB IP/write?db=home'
```

# Drivetemps.sh
This script will go on your box with the rest of your scripts for Grafana.  
This is one of those scripts that requires that "password" file I mentioned in the original readme. Simply update the link to that file, or if your password differs, create another one and link it.   
These do require hard links so please make sure you provide the entire file path.   
```
connect=$(sshpass -f /home/hammer/scripts/password ssh
```
Lastly, update the IP to your FreeNAS box. 
```
root@10.10.10.63
```

# Service
Service file is pretty straight forward. 
```
sudo nano /lib/systemd/system/drivetemps.service
```

Paste in the script and update your username and file path to match your system. 

```
systemctl enable drivetemps.service
systemctl start drivetemps.service
```
