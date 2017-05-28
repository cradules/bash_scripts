#!/bin/bash
#set -x

############################################################################################
#Author: Constantin Radulescu
#QunaticEdge
#Function: Reading machinery kerberos.io and build the vhost
###########################################################################################

VHOST=$1
DOCKERTYPE=$2
DATE=$(date +%d-%m-%y_%T)
VHOSTTMP="/tmp/vhost_$DATE"
PORTTMP="/tmp/port_$DATE"
VHOSTPORT="/tmp/vhostport_$DATE"
DEFAULTCONF="/etc/httpd/conf.d/default.quanticedge.ro.conf.orig"

#Check number of arguments
	if [[ "$#" -ne 2 ]]
		then
		echo "Illegal number of parameters"
		exit 1
	fi



#Check if first given parameter has a match

	if [[ $(docker ps | grep -c $VHOST) -eq 0 ]]
		then
		echo "First given parameter $VHOST could not be found .. exiting"
		exit 1
	elif [[ $(docker ps | grep -c $DOCKERTYPE) -eq 0 ]]
		then 
		echo "Secound given parameter $DOCKERTYPE could not be found .. exiting"
	fi
	

	if [[ $(docker ps | grep $VHOST | grep -m1 $DOCKERTYPE | awk '{print $12}' | awk -F '_' '{print $2}' ) = "machinery" ]]
		then
		#Read vhost and ports for machinery
		docker ps | grep  $VHOST | grep $DOCKERTYPE | awk '{print $12}' | awk -F '_' '{print $1}'  >> $VHOSTTMP 
		docker ps | grep  $VHOST | grep $DOCKERTYPE | awk '{print $11}' | awk -F ':' '{print $2}' | awk -F '-' '{print $1}' >> $PORTTMP
	elif [[ $(docker ps | grep $VHOST | grep -m1 $DOCKERTYPE | awk '{print $13}' | awk -F '_' '{print $2}') = "web" ]]
		then
		#Read vhost and ports for web
		docker ps | grep $VHOST | grep $DOCKERTYPE | awk '{print $13}' | awk -F '_' '{print $1}' >> $VHOSTTMP
		docker ps | grep $VHOST | grep $DOCKERTYPE | awk '{print $12}' | awk -F ':' '{print $2}' | awk -F '-' '{print $1}' >> $PORTTMP
	fi 


#Build List with vhosts and corresponding ports
while read -r a && read -r b <&3
do
echo "$a $b" >> $VHOSTPORT 
done < $VHOSTTMP 3<$PORTTMP 


#Check if the list is valid:

while read -r x y 
do
echo $x $y
COUNT=$(docker ps | grep $x | grep -c $y)

	if [[ $(docker ps | grep $VHOST  | grep -m1 $DOCKERTYPE | awk '{print $12}' | awk -F '_' '{print $2}') = "machinery" ]]
		then
		CONF="../configs/$x"mac".quanticedge.ro.conf"
	elif  [[ $(docker ps | grep $VHOST | grep -m1 $DOCKERTYPE | awk '{print $13}' | awk -F '_' '{print $2}') = "web" ]]
		then
		CONF="../configs/$x.quanticedge.ro.conf"
	fi

	if [[ $COUNT -ne 1 ]]
		then
		echo "ERROR...The list $VHOSTPORT is not correct. The name of the docker dose not corresponding to port"
		exit 1
	else
		cp $DEFAULTCONF $CONF
		sed -i "s/\<sid\>/$x/g" $CONF 
		sed -i "s/\<sidport\>/$y/g" $CONF

	fi
done < $VHOSTPORT



#Clean up
rm $VHOSTTMP $PORTTMP $VHOSTPORT
