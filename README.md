# Cyan Server Grafana Setup!

If you're like me, you want to set up Grafana and have it looking nice and pretty, but you just don't know where to start and there are too many guides that are not very detailed or just don't have the right information. I'm created this guide to attempt to resolve that issue by making this extremely easy and straight forward, as well as by putting as much detail in to the process as I can. 

**So lets jump right on into it!**

First thing's first. We need to install Docker and the containers for Grafana, InfluxDB, CollectD, and Graphite. I've attempted to make this as easy as possible by creating a script that will install everything we need to get started. The script will also add systemd service files so that when we boot the VM, the containers start automatically. 

To accomplish this, we'll use the <html><strong><a href="https://github.com/tylerhammer/grafana/blob/master/setup.sh">Setup.sh</a></strong></html> script. Should you prefer to go through the process step by step for learning purposes, I've added comments to the script to explain it step by step as best I could. 

<html></br></html>

**1. Lets download the script using wget, and the RAW link to the script on github. This will download the script and rename it to "setup.sh".**
```
wget https://raw.githubusercontent.com/tylerhammer/grafana/master/setup.sh - O setup.sh
```

<html></br></html>

**2. Next we need to give it permission to run.**
```
sudo chmod +x setup.sh
```

<html></br></html>

**3. Of course, now we need to run it!**
```
./setup.sh
```

<html></br></html>

Once the script has finished, it will reboot the VM. This is to apply a change where we remove the need to use "sudo" before a docker command. 

Once we are booted back up, run <html><code>docker ps -a</code></html>. This will list all current containers and their status. We are looking for something a long the lines of {{:s7tkuf9.png|}}

<html></br></html>

If you get that as a return, then we are all set up and Grafana should be working! Give it a test at <html><strong>http://IPADDRESS:3000</strong></html>

If you're able to access Grafana, Congrats! You've officially set up the base for your Grafana server!

<html></br></html>

Continue on to the next step where we look at some scripts to start getting data into your InfluxDB server and into Grafana.