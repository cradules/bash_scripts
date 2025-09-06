#!/bin/bash

##########################################################
#Description: Starts Hygieia UI
#Author: Constantin Radulescu
#########################################################


pid () {
netstat -tenpl | grep 3000 | awk '{print $9}' | awk -F '/' '{print $1}'
}

start () { 
cd /usr/local/src/hygieia/UI/
./startui.sh
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
