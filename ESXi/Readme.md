# ESXi CPU & Memory

This script was created and modified by reddit users /u/imaspecialorder, /u/dantho, /u/DXM765 & /u/just_insane

# ESXi.sh
This script requires a little more editing then the rest. 

First thing to update is the #Variables. Update them with your ESXi IP, and the root password. (Lines 13 & 14)
```
ESXiIP=10.10.10.62 #ESXi IP ADDRESS
ESXiPass=#ESXi Root Password
```

Second thing to update, is the link to the password file, as well as the IP to ESXi in the following line. (Line 17)
```
corecount=$(sshpass -f /home/hammer/scripts/password ssh -oStrictHostKeyChecking=no -t root@10.10.10.62 "grep -c ^processor /proc/cpuinfo" 2> /dev/null)
```

Next we want to update the IP to ESXi again. (Line 33)
```
CPUs[$i]="$(snmpget -v 2c -c Public 10.10.10.62 HOST-RESOURCES-MIB::hrProcessorLoad."$i" -Ov)"
```

Update the IP for InfluxDB as well as your database of choice (Line 36)
```
curl -i -XPOST 'http://10.10.10.104:8086/write?db=home' --data-binary "esxi_stats,host=esxi3,type=cpu_usage,cpu_number=$i value=${CPUs[$i]}"
```

Again, we need to update the link to the password file and the ESXi IP. (Line 41)
```
hwinfo=$(sshpass -f /home/hammer/scripts/password ssh -oStrictHostKeyChecking=no -t root@10.10.10.62 "esxcfg-info --hardware")
```

Finally, one more edit to the InfluxDB IP and database of choice (Line 82)
```
curl -i -XPOST 'http://10.10.10.104:8086/write?db=home' --data-binary "esxi_stats,host=esxi3,type=memory_usage value=$pcent"
```

And you're set! 

! I did have trouble with ESXi 6.5 randomly shutting SNMP off on me. 

# Service
Service file is simple.
```
sudo nano /lib/systemd/system/esximon.service
```

Paste in the file, update the username and file path to match your system. 

```
systemctl enable esximon.service
systemctl start esximon.service. 