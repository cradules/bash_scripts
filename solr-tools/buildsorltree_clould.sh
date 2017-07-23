#!/bin/bash
#set -x
SORLVER=
TARGETVERS=
COREPATH=
TARGETPATH=
CHECKSOLR=$(ps -ef | grep solr.install.dir | grep -v "grep" | awk '{print $2}' | wc -l)
NUMSHARDS=1
SHARD="shard$NUMSHARDS"

MYID=$(cat /hybris/zookeeper/data/myid)



#Read input and ajust it to the script needs



	while [[ "$SORLVER" = ""  ]]
			do
			clear
			echo -n "Provide present solr version (must be an integer) followed by [ENTER]:"
			read SORLVER
				if ! [[ "$SORLVER"  =~ [4-5] ]]
					then
					echo "Suported verison to upgrade are 4.x, 5.x"
					echo "$SORLVER is not an integer for suported verisons. The integer can be 4 or 5...exiting!"
					exit 1
				fi 
	done


	while [[ $TARGETVERS = "" ]]
		do
		clear
		echo -n "Provide provide the target version upgrade (must be an integer) followed by [ENTER]:"
		read TARGETVERS
			if ! [[ "$TARGETVERS"  =~ [5-6] ]]
				then
				echo "Tragets version upgrades can be 5.x or 6.x"
				echo "Target upgrade must be an integer for suported version, 5 or 6...exiting!"
				exit 1
			fi

	done
	
	while [[ $COREPATH = "" ]]
		do
		clear
		echo -n "Provide the path to the cores version $SORLVER that you want to upgrade followed by [ENTER]:"
		read COREPATH
			if [[ ! -d $COREPATH ]]
                                then
                                echo $COREPATH not a directory...exiting!
                                exit 1
                        fi
			
			if [[ "$COREPATH" != "*/" ]]
				then
				COREPATH=$COREPATH/
			fi

	done

	while [[ $TARGETPATH = "" ]]
		do
		clear
		echo -n "Provide the path to the solr cores path verison $TARGETVERS followed by [ENTER]:"
		read TARGETPATH
                        if [[ ! -d $TARGETPATH ]]
                                then
                                echo $TARGETPATH not a directory...exiting!
                                exit 1
                        fi
			
			if [[ "$TARGETPATH" != "*/" ]]
				then
				TARGETPATH=$TARGETPATH/
			fi

	done
clear
echo "Please review the below information if is corect"
echo " " 
echo "Cores solr version 4 path is $COREPATH"
echo "Cores sorl version 6 path is $TARGETPATH"
echo " "
	

	while true 
	do
		read -p "Is this information correct?" yn
          		case $yn in
          		[Yy]* ) echo "Script will be executing with given data today $(date)"; break;;
          		[Nn]* ) echo "Exiting..."; exit;;
          		* ) echo "Please answer yes or no.";;
		esac
	done

	

#Main

#STOP SOLR

	if [[ $CHECKSOLR -gt 0 ]]
		then
		while true
		do
    			read -p "Solr services are going to be stoped. Do you wish to continue?" yn
    				case $yn in
        			[Yy]* ) sudo /etc/init.d/solr stop; break;;
				[Nn]* ) echo "Exiting..."; exit;;
        			* ) echo "Please answer yes or no.";;
    			esac
		done
	fi

#Make backup to old core
rsync -aPq $COREPATH cores.bkp/
echo "A backup of $COREPATH was done on cores.bkp"

#Copy old cores to new core
rsync -aP $COREPATH $TARGETPATH



		for y in $(ls -l $COREPATH | grep ^d | awk '{print $9}')
		do
		if [[ $TARGETVERS -eq 6 ]]
			then
			rsync -aPq  $TARGETPATH/$y/ydata/ $TARGETPATH/$y/data/
			rm -rf  $TARGETPATH/$y/ydata
			rsync -aPq  $TARGETPATH/$y/index/ $TARGETPATH/$y/data/index/
			rm -rf  $TARGETPATH/$y/index
	
	
			#if [[ ! -d $TARGETPATH/$y/conf ]]
				#then
				#rsync -aP /hybris/solr/server/solr/configsets/default/conf/ $TARGETPATH/$y/conf/
			#fi

			echo "name=$y"_"$SHARD"_"replica$MYID" > $TARGETPATH/$y/core.properties
			echo "collection=$y" >> $TARGETPATH/$y/core.properties
			echo "shard=$SHARD" >> $TARGETPATH/$y/core.properties
			echo "configSet=default" >> $TARGETPATH/$y/core.properties
			echo "collection.configName=default" >> $TARGETPATH/$y/core.properties
			echo "coreNodeName=core_node$MYID" >> $TARGETPATH/$y/core.properties
			upgradeindex/upgradeindex.sh -s -t $TARGETVERS $TARGETPATH/$y
		fi
		done

#START SOLR
sudo /etc/init.d/solr start
