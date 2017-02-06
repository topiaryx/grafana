#!/bin/bash
#
# This script is designed to fix an SNMP issue with ESXi. Please use it at your own risk.

# Collect Information

echo -n "Welcome to the repair  script for ESXi SNMP. This script is designed to resolve the issue where you recieve "Missing Field Value" as an outcome of the esxi script. This script will ask for some data and make all the necessary$
echo
echo -n "This script will SSH into your ESXi host. It will then backup and change your snmp.xml file, and then apply changes. "

echo
echo

echo -n "Press any key to continue"
read -rsn1

echo
echo

echo -n "What is the IP of your ESXi host? = "
read ESXIP

echo

echo -n "What is the root username of your ESXi host? = "
read ROOT

echo

echo -n "What is the root password of your ESXi host? = "
read -s PASSWORD


# SSH into host
sshpass -p ${PASSWORD} ssh ${ROOT}@${ESXIP} << EOF

cd /etc/vmware
cp snmp.xml snmp.xml.backup

cat  >/etc/vmware/snmp.xml<< DOF
<?xml version="1.0" encoding="ISO-8859-1"?>
<config>
<snmpSettings>
<enable>true</enable>
<port>161</port>
<syscontact></syscontact>
<syslocation></syslocation>
<EnvEventSource>indications</EnvEventSource>
<communities>public</communities>
<loglevel>info</loglevel>
<authProtocol></authProtocol>
<privProtocol></privProtocol>
</snmpSettings>
</config>

DOF

esxcli system snmp set --communities Public
esxcli system snmp set --enable true
esxcli network firewall ruleset set --ruleset-id snmp --allowed-all true
esxcli network firewall ruleset set --ruleset-id snmp --enabled true
esxcli system snmp set -e yes

/etc/init.d/snmpd restart

exit

EOF
