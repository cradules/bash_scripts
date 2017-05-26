#!/bin/bash
#set -x

###############################################################
#Author:
#Constatin Radulescu
#Siteworx
#Function: Backup MONGO DATABASE (zip)
##############################################################

#Vars

DATE=$(date +%d-%m-%y_%T)
BACKUPDIR="./blend_mongo_backup"
MONGOPORT="27017"
HOST="localhost"
ARCHIVE=$(echo mongobackup_$HOST"_"$DATE.zip)
LOG="backup_mongo.log_$DATE"



function showDB () {
mongo<<EOF
show dbs
EOF
                }

DBSIZE=$(echo $(showDB | awk '{print $2}' | grep -v ^[Aa-zZ] | grep -v ^$) | tr -d GB |sed 's/ /+/g' | bc)
CWDSIZE=$(df -h . | grep -v ^[Aa-Zz] | awk '{print $4}')
CWDUNIT=$(echo ${CWDSIZE: -1})
CWDNR=$(echo ${CWDSIZE%?})



#Main
#Check if enogh space

        if [[ "$CWDNR" -lt "$DBSIZE" ]]
                then
        echo "The job cant run. There is not enough free space. Free Space $PWD $CWDSIZE < DB(s) Total Size = $DBSIZE"GB""
	exit 1 
	fi


exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>$LOG 2>&1

#Create working directory

	if [[ ! -d $BACKUPDIR ]]
		then
		mkdir $BACKUPDIR 
	fi
	

#Create backup
mongodump --host "$HOST" --port "$MONGOPORT" --out "$BACKUPDIR"  #With --oplog, mongodump copies all the data from the source database 
								 #as well as all of the oplog entries 
							         #from the beginning to the end
							         #the backup procedure. This operation, in conjunction with mongorestore --oplogReplay, 
								 #allows you to restore a backup that reflects 

		if test "$(ls -A "$BACKUPDIR")"
			then
			zip -r "$ARCHIVE" "$BACKUPDIR"
			rm -rf "$BACKUPDIR"
                	echo ""$ARCHIVE" is ready for download"
		else 
			echo "Something went wrong..."
		fi

RC=$(grep -c -i error $LOG)
exec 1>&3 2>&4
	if [[ -f $LOG || $RC -ne 0 ]]
		then
		cat $LOG
	fi

rm $LOG

	
exit 0
