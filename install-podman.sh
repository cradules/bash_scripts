#!/bin/bash

if (( $EUID != 0 )); then
    echo "Please run as root"
    exit
fi

if [[ -f /etc/os-release ]]
        then
        . /etc/os-release
else
        echo "ERROR: I could not find file /etc/os-release"
        exit 1
fi
apt update
apt install wget
sh -c "echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/x${NAME}_${VERSION_ID}/ /' > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list"
wget -nv https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/x${NAME}_${VERSION_ID}/Release.key -O Release.key
apt-key add - < Release.key
apt-get update -qq
apt-get -qq -y install podman
mkdir -p /etc/containers
echo -e "[registries.search]\nregistries = ['docker.io', 'quay.io']" | sudo tee /etc/containers/registries.conf

sed -i 's/#cgroup_manager = "systemd"/cgroup_manager = "cgroupfs"/g' /usr/share/containers/containers.conf
sed -i 's/#events_logger = "journald"/events_logger = "file"/g' /usr/share/containers/containers.conf

podman info
podman run hello-world
RC=$(echo $?)
if [[ ${RC} -eq 0 ]]
then
        echo "Install process completed succesfully"
else
        "ERROR: Installation process failed!"
fi
