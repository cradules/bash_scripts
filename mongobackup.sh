set -x
#!/bin/bash
#HOST=mongo_solr01-test-useast.belden.siteworx.com
HOST=localhost
BACKUPDIR="./mongobackup/"
PORT="27017"
TMPFILE01="/tmp/dbsize"
CWDSIZE=$(df -h . | tail -1 |awk '{print $4}' | sed "s/[A-Za-z]//g")

function CHECKHOST () {
    ping -c 1 $HOST >/dev/null 2>&1; echo $?
    }

    if [[ $(CHECKHOST) -eq 0 ]]
        then
mongo --host $HOST <<EOF > $TMPFILE01
show dbs
EOF
    else
        echo "$HOST not reachable"
        exit 1
    fi


DBSIZE=$(echo $(cat /tmp/dbsize | grep GB | awk '{print $2}' | tr -d GB) | sed 's/ /+/g' | bc)
DBPACE=$((DBSIZE*2))
NEEDSPACE=$((DBPACE+2))


        if [[ ! -f $BACKUPDIR ]]
                then
                mkdir $BACKUPDIR
        fi

        if [[ $CWDSIZE -lt $NEEDSPACE ]]
                then
                echo "There is not enough space on $PWD to run the backup job"
                echo "The total space we need on $PWD is $NEEDSPACE"GB" "
                echo "Please take in consideration to increase the space for $PWD with $NEEDSPACE"GB""
                exit 1
        fi

    if [[ $(CHECKHOST) -eq 0 ]]
        then
        mongodump --host $HOST --port $PORT --out $BACKUPDIR
        zip $HOSTNAME.backupmongodb.zip $BACKUPDIR
        rm -rf $BACKUPDIR $TMPFILE01
    else
        echo "$HOST not reachable"
        exit 1
    fi
rm -rf $BACKUPDIR $TMPFILE01
