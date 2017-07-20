#!/bin/bash

#########################################################################
#Ahuthor: Constantin Radulescu (Siteworx)
#Main: Adding apache to hybris group and fix permision, 775 dir, 664 files
##########################################################################

#Check if apache user is part of hybris group

HYBRISHOME="/hybris/hybris"
HYBRISGROUP=$(id apache | grep -c hybris)

function spinner () {
PID=$!
i=1
sp="/-\|"
	echo -n ' '
	while [ -d /proc/$PID ]
		do
  		printf "\b${sp:i++%${#sp}:1}"
	done
}


	if [[ $HYBRISGROUP -eq 0 ]]
		then
		echo "User apache is not part of hybris group"
		echo "Adding apache user to hybris group"
		usermod -a -G hybris apache
	fi

#Change directory permision to 775
	clear
	echo "Changing directory permissions to 775 recursively for $HYBRISHOME"
	echo "This might take a while"
	find $HYBRISHOME -type d -exec chmod 775 {} \; & spinner
	echo "Done"
#Change file permisions
	clear
	echo "Changing file permissions from 755 to 775 and from 644 to 664 recursively for $HYBRISHOME"
	echo "This might take a while"
	find $HYBRISHOME -perm 755 -type f -exec chmod 775 {} \; & spinner
	find $HYBRISHOME ! -perm 775 -type f -exec chmod 664 {} \; & spinner
	echo "Done"
	
