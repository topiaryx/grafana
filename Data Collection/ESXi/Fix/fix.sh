#!/bin/bash
#
# This script is designed to fix an SNMP issue with ESXi. Please use it at your own risk.

# Collect Information

echo -e "\e[7mWelcome to the repair  script for ESXi SNMP. This script is designed to resolve the issue where you recieve "Missing Field Value" as an outcome of the esxi script. This script will ask for some data and make all the necessary changes. \e[0m"
echo
echo -e "\e[7mThis script will SSH into your ESXi host. It will then backup and change your snmp.xml file, and then apply changes. \e[0m"

echo
echo

echo -e "Press any key to continue"
read -rsn1

echo
echo

echo -e "\e[7mWhat is the IP of your ESXi host? \e[0m"
read -p "> " ESXIP

echo

echo -e "\e[7mWhat is the root username of your ESXi host? \e[0m"
read -p "> " ROOT

echo

echo -e "\e[7mWhat is the root password of your ESXi host? \e[0m"
read -p "> " -s PASSWORD

clear

# SSH into host
sshpass -p ${PASSWORD} ssh ${ROOT}@${ESXIP} << EOF

echo -e "\e[36mBacking up xml file.\e[0m"

cd /etc/vmware >/dev/null 2>&1
cp snmp.xml snmp.xml.backup >/dev/null 2>&1

echo -e "\e[36mUpdating xml file.\e[0m"

cat  >/etc/vmware/snmp.xml<< DOF >/dev/null 2>&1
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

echo -e "\e[36mUpdating firewall.\e[0m"

esxcli system snmp set --communities Public >/dev/null 2>&1
esxcli system snmp set --enable true >/dev/null 2>&1
esxcli network firewall ruleset set --ruleset-id snmp --allowed-all true >/dev/null 2>&1
esxcli network firewall ruleset set --ruleset-id snmp --enabled true >/dev/null 2>&1
esxcli system snmp set -e yes >/dev/null 2>&1

echo -e "\e[36mRestarting SNMP service.\e[0m"

/etc/init.d/snmpd restart >/dev/null 2>&1

exit

EOF

clear

echo -e "\e[7mThe fix should now be applied, and you should be able to restart your esxi script. \e[0m"
echo -e "\e[7mIf you're still having trouble please reach out to me git@tylerhammer.com or on Discord Hammer#4341. \e[0m"
