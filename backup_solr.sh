#!/bin/bash
#set -x

###############################################################
#Author:
#Constatin Radulescu
#Siteworx
#Function: Backup SOLR instance (zip)
##############################################################

#Vars

DATE="$(date +%d-%m-%y_%T)"
BACKUPDIR="$(df -h | grep solr | awk '{print $6}')"
HOST="localhost"
ARCHIVE="$(echo solrbackup_$HOST"_"$DATE.zip)"
LOG="backup_solr.log_$DATE"
SOLRSIZE="$(df -h | grep solr | awk '{print $4}')"
CWDSIZE="$(df -h . | grep -v ^[Aa-Zz] | awk '{print $4}')"


function  solrunit {
	echo ${SOLRSIZE: -1}

}


function cwdunit {
	echo ${CWDSIZE: -1}
}

function solrnr {
	echo ${SOLRSIZE%?}
}

function cwdnr {
	echo ${CWDSIZE%?}
}







#Main
#Transform MB to GB
	if [[ "$(solrunit)" = "M" ]]
		then
		SOLRGB="$(echo $((solrnr/1024)) | bc -l)"	
	else
		SOLRGB=`echo $(solrnr)`
	fi
	
	if [[ "$(cwdunit)" = "M" ]]
		then
		CWDGB="$(echo $((cwdnr/1024)) | bc -l)"
	else
		CWDGB=`echo $(cwdnr)`
        fi	


#Make sure you have enough space on 

        if [[ $CWDGB -lt $SOLRGB ]]
                then
        echo "The job cant run. There is not enough free space. Free Space = $CWDSIZE<DBs Total Size = $SOLRSIZE"
	exit 1 
	fi


exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>$LOG 2>&1

#Creata working directory

	if [[ ! -d $BACKUPDIR ]]
		then
		mkdir $BACKUPDIR 
	fi
	

#Create backup

		if test "$(ls -A "$BACKUPDIR")"
			then
			zip -r "$ARCHIVE" "$BACKUPDIR"
                	echo ""$ARCHIVE" is ready for download"
		else 
			echo "Something went wrong..."
		fi

RC=$(grep -c -i error $LOG)
exec 1>&3 2>&4
	if [[ -f $LOG  || $RC -ne 0 ]]
		then
		cat $LOG
	fi

#Clean up

rm $LOG

	
exit 0
