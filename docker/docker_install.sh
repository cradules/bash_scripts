#!/bin/bash
#set -x
##############################################################
#Get Docker for CentOS
#Author: Constantin Radulescu
#Function: Install Docker
##############################################################


#Uninstall old versions

LOG=/tmp/dockerinstall.log
clear
echo -ne '#                     (1%)\r'
#Build log
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>$LOG 2>&1


yum remove docker docker-common container-selinux docker-selinux docker-engine

exec 1>&3 2>&4
echo -ne '#####                     (25%)\r'
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>>$LOG 2>&1

#Add docker repo
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo  "https://download.docker.com/linux/centos/docker-ce.repo"

#Enable repo
yum-config-manager --enable docker-ce-edge


#Install Docker CE (Comunit Edition)
yum makecache fast -y
yum install docker-ce -y

exec 1>&3 2>&4
echo -ne '##########                    (50%)\r'
sleep 1
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>>$LOG 2>&1


#Disable Docker repo
yum-config-manager --disable docker-ce-edge


#Enable Docker
systemctl enable docker

#Start Docker
systemctl start docker

exec 1>&3 2>&4
echo -ne '##############################  (100%)\r'
sleep 1
clear


#Check if docker running
docker ps > /dev/null
RC=$(echo $?)

if [[ $RC -eq 0 ]]
	then
	echo "Docker succefully installed"
else
	echo "There was an error during the install. Docker is not running. Please check log"
	cat "$LOG"
fi

rm $LOG
exit 0
