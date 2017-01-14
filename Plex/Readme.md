#Instructions for configuring

Before we begin, this script was created by reddit user /u/BarryCarey. His original scripts can be found https://github.com/barrycarey/Plex-Data-Collector-For-InfluxDB

## Requirements

This script requires Python3+ .

Once Python3 is installed you'll need to install InfluxDB and Request for Python (Different then normal InfluxDB)

This can be achieved by doing
```
pip3 install -r requirements.txt
```


## Config.ini

You will need to update the following information  
**[INFLUXDB]**  
**Address** - This is the IP address of your InfluxDB instance  
**Port** - Should be 8086 unless you changed it while installing.   
**Database** - The database you created for this database  
**Username** - Username for database. Generally left as root  
**Password** - Password for database. Generally left as root  

**[PLEX]**  
**Username** - Your plex username  
**Password** - Your plex password  
**Servers** - Your server address  
 
**[LOGGING]**  
**LogFile** - Give this a hard location to wherever your scripts are at. 


## plexInfluxdbCollector.py
At the end of the script is the location where it looks for the config.ini file. You need to give it a hard location. Line 556 on Github. 
```
('--config', default='/home/hammer/scripts/plex/config.ini',
```

! I did run into some interesting permission issues with the output.log file so you may need to create the file before hand and give it the propper permissions. 

# Services
I created a service file to allow this script to run on boot. These service files are for Ubuntu 16.04.  
To use the file
```
sudo nano /lib/systemd/system/plexmon.service
```
Paste in the script and update the user and file path according to your setup.   
Then all you need to do is 
```
systemctl enable plexmon.service
systemctl start plexmon.service
```
