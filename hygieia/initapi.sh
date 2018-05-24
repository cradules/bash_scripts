#!/bin/bash

##########################################################
#Description: Starts Hygieia
#Author: Constantin Radulescu
#########################################################

ENCRYPTORPASSWORD="hygieiasecret"

pid () {
ps -ef | grep api.jar | grep -v "grep" | awk '{print $2}'
}

start () { 
java -jar api.jar --spring.config.location=/usr/local/src/hygieia/api/api.properties -Djasypt.encryptor.password=$ENCRYPTORPASSWORD &
}

stop () {
kill -s TERM $(pid)

}

case "$1" in
        start)
		echo "Starting services..."
		sleep 1 
		start
        ;;
        stop)
                echo "Stopping services.." >&2
                stop
        ;;
        retart)
                echo "Stopping services.." >&2
                stop
                echo 'Starting service…' >&2
                start
        ;;
  *)
        echo "Usage: $0 {start|stop|restart}"
esac
