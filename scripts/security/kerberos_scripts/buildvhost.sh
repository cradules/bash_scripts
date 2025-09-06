#!/bin/bash
#set -x

############################################################################################
#Author: Constantin Radulescu
#QunaticEdge
#Function: Reading machinery kerberos.io and build the vhost
###########################################################################################

DOCKERINPUT="/tmp/dockertinput.txt"


#Check number of arguments
        if [[ "$#" -ne 1 ]]
                then
                echo "Illegal number of parameters"
                exit 1
        else
                echo $1 > $DOCKERINPUT
        fi

CONGIF="../configs/kerberos.conf"
USER=$(cat /root/.passhttp | awk '{print $1}')
PASS=$(cat /root/.passhttp | awk '{print $2}')
VHOST=`echo $(cat $CONGIF | awk '{print $1}')`
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
DNSTMP="/tmp/dnstmp"



#Check if first given parameter has a match

	if [[ $(docker ps | grep -c "$VHOST") -eq 0 ]]
		then
		echo "First given parameter "$VHOST" could not be found .. exiting"
		exit 1
	elif [[ $(docker ps | grep -c "$DOCKERTYPE") -eq 0 ]]
		then 
		echo "Secound given parameter "$DOCKERTYPE" could not be found .. exiting"
	fi
	

	if [[ $(docker ps -a | grep -e "$VHOST" | grep "$DOCKERTYPE" | grep "0.0.0.0" | awk '{print $(NF-0)}' | awk -F "_" '{print $2}' | tail -1) = "machinery" ]]
		then
		#Read vhost and ports for machinery
		docker ps -a | grep "$VHOST" | grep "$DOCKERTYPE"| grep "0.0.0.0" | awk '{print $(NF-0)}' | awk -F "_" '{print $1}'  >> $VHOSTTMP 
		docker ps -a | grep "$VHOST"| grep "$DOCKERTYPE"| grep "0.0.0.0" | awk '{print $(NF-1)}' | awk -F ':' '{print $2}' | awk -F '-' '{print $1}' >> $PORTTMP
		CONF="../configs/$x"mac".quanticedge.ro.conf"
	fi
	
	if [[ $(docker ps -a | grep -e "$VHOST" | grep "$DOCKERTYPE" | grep "0.0.0.0" | awk '{print $(NF-0)}' | awk -F "_" '{print $2}' | head -1) = "web" ]]
		then
		#Read vhost and ports for web
		docker ps -a | grep "$VHOST" | grep "$DOCKERTYPE"| grep "0.0.0.0" | awk '{print $(NF-0)}' | awk -F "_" '{print $1}' >> $VHOSTTMP
		docker ps -a | grep "$VHOST"| grep "$DOCKERTYPE"| grep "0.0.0.0" | awk '{print $(NF-1)}' | awk -F ':' '{print $2}' | awk -F '-' '{print $1}' >> $PORTTMP
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
MACDNS="$x"mac".quanticedge.ro"
WEBDNS="$x"."quanticedge.ro"

#Define conf

	if [[ $(docker ps -a | grep -e "$VHOST" | grep "$DOCKERTYPE" | grep "0.0.0.0" | awk '{print $(NF-0)}' | awk -F "_" '{print $2}' | tail -1) = "machinery" ]]
		then
		CONF="../configs/$x"mac".quanticedge.ro.conf"
	elif [[ $(docker ps -a | grep -e "$VHOST" | grep "$DOCKERTYPE" | grep "0.0.0.0" | awk '{print $(NF-0)}' | awk -F "_" '{print $2}' | head -1) = "web" ]] 
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
			if [[ $(docker ps -a | grep -e "$VHOST" | grep "$DOCKERTYPE" | grep "0.0.0.0" | awk '{print $(NF-0)}' | awk -F "_" '{print $2}' | head -1) = "web" ]] 
				then
				sed -i "s/\<sid\>/$x/g" $CONF
		 
			elif [[ $(docker ps -a | grep -e "$VHOST" | grep "$DOCKERTYPE" | grep "0.0.0.0" | awk '{print $(NF-0)}' | awk -F "_" '{print $2}' | tail -1) = "machinery" ]] 
				then
				sed -i "s/\<sid\>/"$x"mac/g" $CONF
			fi
		sed -i "s/\<sidport\>/$y/g" $CONF
		mv -f "$CONF" /etc/httpd/conf.d/
			
#Build site

			if [[ $DOCKERTYPE = "web" ]]
				then
					if [[ ! -d $SITE ]]
						then
						mkdir $SITE
					fi
						
					if [[ ! -d $WORKINGDIR ]]
						then 
						mkdir $WORKINGDIR
				
					fi
				

				cp $DEFAULTDIV "$WORKINGDIR"/"$CAMNUM".txt
				sed -i "s/CAMNR/"$CAMUP"/g" "$WORKINGDIR"/"$CAMNUM".txt
				sed -i "s/camnr/"$CAMNUM"/g" "$WORKINGDIR"/"$CAMNUM".txt
				sed -i "s;CAMURL;"$URLWEB";g" "$WORKINGDIR"/"$CAMNUM".txt
				sed -i "s;MACURL;"$URLMAC";g" "$WORKINGDIR"/"$CAMNUM".txt
				cp $DEFAULTCAM   $SITE/"$CAMNUM".html
				sed -i "s;MACURL;"$URLMAC";g" $SITE/"$CAMNUM".html
#DNS
				echo $MACDNS >> $DNSTMP
				echo $WEBDNS >> $DNSTMP 
			fi

	fi
done < $VHOSTPORT
	if [[ $DOCKERTYPE = "web" ]]
		then
		cp "$DEFAULTINDEX" "$WORKINGDIR"
		for w in `ls $WORKINGDIR | grep -v index`
		do
			sed -i "\$r $WORKINGDIR/$w" "$WORKINGDIR"/default.index.html
		done

		sed  -i '$i</body>' $WORKINGDIR/default.index.html
		sed  -i '$i</html>' $WORKINGDIR/default.index.html
		cp $WORKINGDIR/default.index.html $SITE/index.html
		tar -cf $SITE"."tar $SITE 2>/dev/null
		echo "Site archive ready for download $SITE"."tar"
		echo "Setup a CNAME to point on $HOSTNAME.quanticedge.ro for next DNS entries:"
		cat $DNSTMP
	fi


#Clean up
rm -f $VHOSTTMP $PORTTMP $VHOSTPORT $VHOSTINPUT $DOCKERINPUT $USERINPUT $PASSINPUT $DNSTMP 2>/dev/null 
rm -rf $WORKINGDIR 2>/dev/null
rm -rf $SITE 2>/dev/null

systemctl restart httpd

