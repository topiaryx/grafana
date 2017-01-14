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
**Port** - Should be 8086 unless you changed it while installing   
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


