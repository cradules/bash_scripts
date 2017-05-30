#!/bin/bash
#set -x

#########################################################
#Author: Constantin Radulescu
#QuanticEdge
#Function: Build kerberos compose web/machinery
########################################################

CONGIF="../configs/kerberos.conf"
DEFAULTKERCONFIG="../configs/default.docker-compose.yaml"
KERCONF=./docker-compose.yaml
CLIENT="$(cat $CONGIF | awk '{print $1}')"
NUMBERSOFCAM="$(cat $CONGIF | awk '{print $2}')"


#Build filesystem
	if [[ ! -d /docker/$CLIENT ]]
		then
		mkdir -p -m 400 /docker/$CLIENT
	fi



lvcreate -L 10G -n $CLIENT vgkerberos01
mkfs.ext4 /dev/vgkerberos01/$CLIENT
echo "/dev/vgkerberos01/$CLIENT /docker/$CLIENT ext4 defaults 1 2" >> /etc/fstab
mount -a 
	if [[ $(echo $?) -ne 0 ]]
		then
		echo "There was an error mounting /dev/vgkerberos01/$CLIENT to /docker/$CLIEN ...Exiting"
		exit 1
	fi



#Build containers

for ((y=0;y<$NUMBERSOFCAM;y++))
	do
 	function LASTPORTGIVEN () {
	#echo $(docker ps -a | grep -e web -e mac | awk '{print $11 $12}' | awk -F ':' '{print $2}' | awk -F '-' '{print $1}' | sort -n | tail -1)
	echo $(docker ps -a | grep -e web -e mac | grep "0.0.0.0" | awk '{print $(NF-1)}' | awk -F ':' '{print $2}' | awk -F '-' '{print $1}'| sort -n | tail -1)
}
LASTPORTGIVEN

CAM=`echo $((y+1))`
	if [[ $(LASTPORTGIVEN) -le "3700" ]]
		then
		MACPORT=$((3700+1))
	else
		MACPORT=$(($(LASTPORTGIVEN)+1))
	fi

WEBPORT=$((MACPORT+1))
	mkdir -p /docker/$CLIENT/cam0$CAM
	cp $DEFAULTKERCONFIG $KERCONF
       	sed -i "s/clientsid/$CLIENT/g" $KERCONF
	sed -i "s/macport/$MACPORT/g" $KERCONF
	sed -i "s/webport/$WEBPORT/g" $KERCONF
	sed -i "s/camnr/cam0$CAM/g" $KERCONF
	docker-compose -p "$CLIENT""cam0$CAM" up -d

sleep 15
rm $KERCONF
done

#Build site

for n in mac web
do
./buildvhost.sh $n
done
