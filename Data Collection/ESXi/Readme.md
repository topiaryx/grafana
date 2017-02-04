# ESXi CPU & Memory

This script was created and modified by reddit users /u/imaspecialorder, /u/dantho, /u/DXM765 & /u/just_insane & /u/tylerhammer

I've edited this script to run off a config file now. 

Simply download both items in to the same folder and update the config file with the requested information. 


**NOTE: I did have trouble with ESXi 6.5 randomly shutting SNMP off on me.**

# Service
Service file is simple.
```
sudo nano /lib/systemd/system/esximon.service
```

Paste in the file, update the username and file path to match your system. 

```
systemctl enable esximon.service
systemctl start esximon.service. 
