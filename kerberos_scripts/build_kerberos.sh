#!/bin/bash
#set -x

#########################################################
#Author: Constantin Radulescu
#QuanticEdge
#Function: Build kerberos compose web/machinery
########################################################

CONGIF="../configs/kerberos.conf"
DEFAULTKERCONFIG="../configs/default.docker-compose.yaml"
KERCONF=../../docker-compose.yaml
CLIENT="$(cat $CONGIF | awk '{print $1}')"
NUMBERSOFCAM="$(cat $CONGIF | awk '{print $2}')"

for ((y=0;y<$NUMBERSOFCAM;y++))
	do
	#cp $DEFAULTKERCONFIG $KERCONF
	#sed -i "s/clientsid/$CLIENT/g" $KERCONF
LASTPORTGIVEN=$(docker ps | grep -e web -e mac | awk '{print $11 $12}' | awk -F ':' '{print $2}' | awk -F '-' '{print $1}' | sort -n | tail -1)
CAM=$((y+1))
MACPORT=$((LASTPORTGIVEN+1))
WEBPORT=$((MACPORT+1))


	echo "Camera numeber cam0$CAM"
	echo "Mac port  $MACPORT"
	echo "Web port $WEBPORT"
done
