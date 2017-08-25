#!/bin/bash
SERVERNAME=$(uname -n)
NETWORKSYS="/etc/sysconfig/network"
sed -i '/HOSTNAME/,1d' $NETWORKSYS; 
echo "HOSTNAME=$SERVERNAME" >> $NETWORKSYS
grep HOSTNAME  $NETWORKSYS

