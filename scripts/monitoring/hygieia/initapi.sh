#!/bin/bash

##########################################################
#Description: Starts Hygieia
#Author: Constantin Radulescu
#########################################################

# Load encryptor password from environment variable or config file
ENCRYPTORPASSWORD="${HYGIEIA_ENCRYPTOR_PASSWORD:-}"

if [ -z "$ENCRYPTORPASSWORD" ]; then
    echo "Error: HYGIEIA_ENCRYPTOR_PASSWORD environment variable is not set"
    echo "Please set it with: export HYGIEIA_ENCRYPTOR_PASSWORD='your_password'"
    exit 1
fi

pid () {
ps -ef | grep api.jar | grep -v "grep" | awk '{print $2}'
}

start () { 
java -jar /usr/local/src/hygieia/api/target/api.jar --spring.config.location=/usr/local/src/hygieia/api/api.properties -Djasypt.encryptor.password=$ENCRYPTORPASSWORD &
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
