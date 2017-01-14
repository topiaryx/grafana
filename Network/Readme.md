# Network Instructions

The scritps are originally from reddit user /u/0110010001100010 . Their original scripts are located here https://github.com/danodemano/monitoring-scripts

# Ping.sh
Updating this script for your use is pretty easy. /u/0110010001100010 did a great job of including in script comments that make editing these pretty straight forward.   
That being said, I'll add a little bit more.   

You will need to update the "curl -i" sections at the bottom to match your InfluxDB address.   
I set this script to run every minute, but you and edit that based on your needs by editing (Updated in seconds) 
```
sleeptime=60
``` 

# Speedtest.sh
The speedtest script is very easy to use. Again, /u/0110010001100010 did an excellent job of making in script comments. 

This script does require speedtest-cli
```
sudo apt-get install speedtest-cli
```
This script was originally set to run every every minute, but I altered it to run every hour.   
Just like the Ping.sh you'll need to update the "curl -i" lines at the bottom of the script. 


# Services
I've created a service script for both Ping and Speedtest. All you need to do is 
```
sudo nano /lib/systemd/system/speedtest.service or ping.service
```
Then paste in the script and adjust the user and the file path based on your setup.  
Then you'll need to do 
```
systemctl enable speedtest.service
systemctl start speedtest.service
```
The same will go for ping.service. 