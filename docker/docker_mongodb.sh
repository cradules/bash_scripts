#!/bin/bash

###################################################################
#This script will create a docker container for mongodb
###################################################################

export PATH=$PATH:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/centos/.local/bin:/home/centos/bin

DOCKERPATH=/var/lib/docker

echo "Please provide the name of the volume(disk) for the DB, followed by [ENTER]:"
read VOLUME

echo "Please provide the name for the docker, followed by [ENTER]:"
read DOCKERNAME

echo "Creating volume $VOLUME"
docker volume create $VOLUME

echo "Listing volumes:"
docker volume ls

echo "Creating container..."

docker run -d \
  --name $DOCKERNAME \
  --mount source=$VOLUME,target=/data/db \
  -d mongo
