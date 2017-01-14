# Cyan Grafana
Grafana Scripts for Cyan Server
Cyan Server is built ontop of 16.04 and Docker so some scripts/commands will change depending on your OS. 

A lot of these scripts have a couple of requirements.

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
