#!/bin/bash
set -x

############################################################################################
#Author: Constantin Radulescu
#QunaticEdge
#Function: Reading machinery kerberos.io and build the vhost
###########################################################################################


VHOSINPUT="/tmp/vhostinput.txt"
DOCKERINPUT="/tmp/dockertinput.txt"
USERINPUT="/tmp/userinput.txt"
PASSINPUT="/tmp/passinput.txt"


#Check number of arguments
        if [[ "$#" -ne 4 ]]
                then
                echo "Illegal number of parameters"
                exit 1
        else
                echo $1 > $VHOSINPUT
                echo $2 > $DOCKERINPUT
		echo $3 > $USERINPUT
		echo $4 > $PASSINPUT
        fi


USER=$(cat $USERINPUT)
PASS=$(cat $PASSINPUT)
VHOST=$(cat $VHOSINPUT)
DOCKERTYPE=$(cat $DOCKERINPUT)
DATE=$(date +%d-%m-%y_%T)
VHOSTTMP="/tmp/vhost_$DATE"
PORTTMP="/tmp/port_$DATE"
VHOSTPORT="/tmp/vhostport_$DATE"
DEFAULTCONF="../configs/default.quanticedge.ro.conf.orig"
DEFAULTINDEX="../camera_console/default.index.html"
DEFAULTCAM="../camera_console/default.cam.html"
DEFAULTDIV="../camera_console/default.div.txt"
SITE="../../"$VHOST"_site"
WORKINGDIR="/tmp/divtemp"




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



while read -r x y 
do
COUNT=$(docker ps | grep $x | grep -c $y)
CAMNUM=$(echo ${x: -5})
CAMUP="$(echo $CAMNUM | tr '[:lower:]' '[:upper:]')"
URLMAC="http://$USER":"$PASS"@"$x"mac".quanticedge.ro"
URLWEB="http://$USER":"$PASS"@"$x"."quanticedge.ro"

#Define conf

	if [[ $(docker ps | grep $VHOST  | grep -m1 $DOCKERTYPE | awk '{print $12}' | awk -F '_' '{print $2}') = "machinery" ]]
		then
		CONF="../configs/$x"mac".quanticedge.ro.conf"
	elif  [[ $(docker ps | grep $VHOST | grep -m1 $DOCKERTYPE | awk '{print $13}' | awk -F '_' '{print $2}') = "web" ]]
		then
		CONF="../configs/$x.quanticedge.ro.conf"
	fi

#Build conf

	if [[ $COUNT -ne 1 ]]
		then
		echo "ERROR...The list $VHOSTPORT is not correct. The name of the docker dose not corresponding to port"
		exit 1
	else
		cp $DEFAULTCONF $CONF
		sed -i "s/\<sid\>/$x/g" $CONF 
		sed -i "s/\<sidport\>/$y/g" $CONF
		mv -f "$CONF" /etc/httpd/conf.d/
			
#Build site

			if [[ $DOCKERTYPE = "web" ]]
				then
					if [[ ! -d $SITE ]]
						then
						mkdir $SITE
					elif [[ ! -d $WORKINGDIR ]]
						then 
						mkdir $WORKINGDIR
				
					fi
				

				cp $DEFAULTDIV "$WORKINGDIR"/"$CAMNUM".txt
				sed -i "s/CAMNR/"$CAMUP"/g" "$WORKINGDIR"/"$CAMNUM".txt
				sed -i "s/camnr/"$CAMNUM"/g" "$WORKINGDIR"/"$CAMNUM".txt
				sed -i "s;CAMURL;"$URLWEB";g" "$WORKINGDIR"/"$CAMNUM".txt
				sed -i "s;MACURL;"$URLMAC";g" "$WORKINGDIR"/"$CAMNUM".txt
				cp "$DEFAULTINDEX" "$WORKINGDIR" 
				cp $DEFAULTCAM   $SITE/"$CAMNUM".html
				sed -i "s;MACURL;"$URLMAC";g" $SITE/"$CAMNUM".html
			fi

	fi
done < $VHOSTPORT

	for w in `ls /tmp/divtemp/`
	do
		sed -i "\$r $WORKINGDIR/$w" "$WORKINGDIR"/default.index.html
	done

	sed  -i '$i</body>' $WORKINGDIR/default.index.html
	sed  -i '$i</html>' $WORKINGDIR/default.index.html
	cp $WORKINGDIR/default.index.html $SITE/index.html



#Clean up
rm $VHOSTTMP $PORTTMP $VHOSTPORT $VHOSINPUT $DOCKERINPUT $USERINPUT $PASSINPUT 
rm -rf $WORKINGDIR
