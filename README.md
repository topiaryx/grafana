# Cyan Grafana
Grafana Scripts for Cyan Server
Cyan Server is built ontop of 16.04 and Docker so some scripts/commands will change depending on your OS.   

I've added a Setup.sh script. This will install Docker, Grafana, Influx, CollectD and Graphite for you on an Ubuntu 16.04 Server VM. 

There are some requirements across the scripts, so if you're planning to use them all, you'll need these three. 

SSHPass
```
sudo apt-get install sshpass
```
SNMPGet
```
sudo apt-get install snmp snmp-mibs-downloader
```
You will also need a password file for ESXi. This isnt the most secure way currently, but it works till I care to create SSH Keys. 
You will put this password wherever your scripts are going to live. The only thing in the file should be your password for ESXi.
```
sudo nano password
```
---

Because of the way systemd works, all scripts need to have hard locations. So if your script has a config file in its folder, you need to link to it directly. Example: /home/hammer/scripts/plex/config.ini instead of just config.ini. 


# Pfsense Data
Pfsense data was one thing that didnt have any scripts, so because it doesnt have a folder, I'll add it here.

Pfsesne data is collected using telegraf. The original guide I used was https://sbaronda.com/2016/06/14/logging-pfsense-metrics-to-influxdb/ , however it was a bit dated so I'll rewrite it here with updated information. 

This will be done over SSH, so if you do not have SSH enabled on your pfsense box, you'll need to enable it by going to System > Adavanced and enabling "Secure Shell Server"

We'll start of by doing sshing into pfsense, for me thats: 
```
ssh admin@10.10.10.1
```

Once connected, will want to use the Shell option, so option 8. 

```
*** Welcome to pfSense 2.3.1-RELEASE (amd64 full-install) on pfSense ***

 WAN (wan)       -> vmx0       -> v4/DHCP4: x.x.x.x/24
 LAN (lan)       -> vmx1       -> v4: 10.10.10.1/24

 0) Logout (SSH only)                  9) pfTop
 1) Assign Interfaces                 10) Filter Logs
 2) Set interface(s) IP address       11) Restart webConfigurator
 3) Reset webConfigurator password    12) pfSense Developer Shell
 4) Reset to factory defaults         13) Update from console
 5) Reboot system                     14) Disable Secure Shell (sshd)
 6) Halt system                       15) Restore recent configuration
 7) Ping host                         16) Restart PHP-FPM
 8) Shell

Enter an Option: 8
```

Next we need to actually install telegraf. As of January 14th 2017, this is the most up to date link. 
```
pkg add \
http://pkg.freebsd.org/freebsd:10:x86:64/latest/All/telegraf-1.1.2.txz
```

Make sure you can start it by 
```
echo 'telegraf_enable=YES' >> /etc/rc.conf
```

Next, we need to update the telegraf.conf file. We only need to update a couple of sections so I'll list those here. I created the database "pfsense" in InfluxDB so I listed it here. Yours may differ depending on what database you create.  
*If I recall correctly, there was only a sample file first. Edit the sample file, then cp it to the conf. (I'll explained this more after we edit the file)*
```
cd /usr/local/etc
vi telegraf.conf.sample
```

```
[[outputs.influxdb]]
  urls = ["http://10.10.10.104:8089"]
  ...
  database = "pfsense"
  ...
  username = "root"
  password = "root"
```
To enable network statstic we need to un comment the [[inputs.net]] section. Only the one line needs to be uncommented unless you wish to alter the settings. By default it will capture all interfaces, and list them seperately.
```
# # Read metrics about network interface usage
 [[inputs.net]]
#   ## By default, telegraf gathers stats from any up interface (excluding loopback)
#   ## Setting interfaces will tell it to gather these explicit interfaces,
#   ## regardless of status.
#   ##
#   # interfaces = ["eth0"]  
```

Once we've updated the files, we need to move the sample file to the primary conf file.
```
cp telegraf.conf.sample telegraf.conf
```
This will cp the file so we always have a "backup". 

Lastly start Telegraf. 

```
cd /usr/local/etc/rc.d
./telegraf start
```

You're all set! 
