#!/bin/bash

##############################################################################
# Script Name: install-hygieia.sh
# Description: Installs Hygieia dashboard with all dependencies
# Author: Constantin Radulescu
# Version: 2.0
# Last Modified: 2025-09-06
#
# Usage: sudo ./install-hygieia.sh <disk_device>
#
# Requirements:
#   - Root privileges
#   - Red Hat/CentOS/RHEL system
#   - Available disk device for LVM setup
#
# Environment Variables:
#   - HYGIEIA_DB_USER: Database username (default: dashboarduser)
#   - HYGIEIA_DB_PASSWORD: Database password (required)
#
# Exit Codes:
#   0 - Success
#   1 - General error
#   2 - Invalid arguments
#   3 - Missing dependencies
##############################################################################

set -euo pipefail

# Script configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly INSTALLPATH="/usr/local/src/hygieia"
readonly USER="hygieia"
readonly VGNAME="vghygieia"
readonly LVNAME="lvhygieia"
readonly GITSOURCE="https://github.com/capitalone/Hygieia.git"

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

show_usage() {
    cat << EOF
Usage: $SCRIPT_NAME <disk_device>

Installs Hygieia dashboard with all required dependencies including:
- MongoDB database
- Java 8 OpenJDK
- Apache Maven
- Node.js
- Git

Arguments:
    disk_device    Block device to use for Hygieia storage (e.g., sdb, sdc)

Environment Variables:
    HYGIEIA_DB_USER      Database username (default: dashboarduser)
    HYGIEIA_DB_PASSWORD  Database password (required)

Examples:
    $SCRIPT_NAME sdb
    HYGIEIA_DB_PASSWORD=mypass $SCRIPT_NAME sdc

EOF
}

# Validate arguments
validate_args() {
    if [[ $# -ne 1 ]]; then
        log_error "Invalid number of arguments"
        show_usage
        exit 2
    fi

    local disk="$1"
    if [[ ! -b "/dev/$disk" ]]; then
        log_error "Device /dev/$disk does not exist or is not a block device"
        exit 2
    fi

    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 2
    fi
}

# Update PATH to include Maven
export PATH="$PATH:/usr/local/src/apache-maven/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/centos/.local/bin:/home/centos/bin"


# Get disk size in GB
get_disk_size() {
    local disk="$1"
    if ! pvdisplay "/dev/$disk" &>/dev/null; then
        log_error "Cannot get size for /dev/$disk - not a physical volume yet"
        return 1
    fi
    pvdisplay "/dev/$disk" | grep "PV Size" | awk '{print $3}' | awk -F '.' '{print $1}'
}

# Create filesystem and mount point
setup_filesystem() {
    local disk="$1"

    log_info "Setting up filesystem for Hygieia..."

    # Check if already mounted
    if grep -q "$LVNAME" /etc/mtab; then
        log_info "Filesystem already exists and is mounted"
        return 0
    fi

    # Create directory with proper permissions
    if [[ ! -d "$INSTALLPATH" ]]; then
        mkdir -p "$INSTALLPATH"
        chmod 755 "$INSTALLPATH"
        log_info "Created directory: $INSTALLPATH"
    fi

    # Create LVM setup
    log_info "Creating LVM setup on /dev/$disk"

    if ! pvcreate "/dev/$disk"; then
        log_error "Failed to create physical volume on /dev/$disk"
        return 1
    fi

    # Calculate size (leave 1GB free)
    local pvsize
    if ! pvsize=$(get_disk_size "$disk"); then
        log_error "Failed to get disk size"
        return 1
    fi
    pvsize=$((pvsize - 1))

    if ! vgcreate "$VGNAME" "/dev/$disk"; then
        log_error "Failed to create volume group $VGNAME"
        return 1
    fi

    if ! lvcreate -L "${pvsize}G" -n "$LVNAME" "/dev/$VGNAME"; then
        log_error "Failed to create logical volume $LVNAME"
        return 1
    fi

    if ! mkfs.ext4 "/dev/$VGNAME/$LVNAME"; then
        log_error "Failed to create ext4 filesystem"
        return 1
    fi

    # Add to fstab and mount
    echo "/dev/mapper/$VGNAME-$LVNAME $INSTALLPATH ext4 defaults 1 2" >> /etc/fstab

    if mount -a; then
        log_success "Filesystem created and mounted successfully"
    else
        log_error "Failed to mount filesystem"
        return 1
    fi
}

#Create user
id $USER &> /dev/null
RC=$(echo $?)
	if [[ $RC -ne 0 ]]
		then
		echo "Adding user $USER"
		adduser $USER
		#Setting owner and permisions
		chown $USER:$USER $INSTALLPATH
		
	else
		echo "User $USER already exist"
	fi
#Setting owner and permisions
                chown $USER:$USER $INSTALLPATH

#Install git
	if [[ $(rpm -qa | grep -w -c git) -ne 1 ]]
		then
		yum install git
	fi


#Install mongoDB

echo "
[mongodb-org-3.6]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/7/mongodb-org/3.6/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-3.6.asc
" > /etc/yum.repos.d/mongodb-org-3.6.repo 

	if [[ $(rpm -qa | grep -c mongodb-org-server) -eq 0 ]]
		then
		yum install -y mongodb-org
		systemctl start mongod
		systemctl enable mongod

		# Database credentials should be provided via environment variables
		DB_USER="${HYGIEIA_DB_USER:-dashboarduser}"
		DB_PASSWORD="${HYGIEIA_DB_PASSWORD:-}"

		if [ -z "$DB_PASSWORD" ]; then
			echo "Warning: HYGIEIA_DB_PASSWORD not set. Please set database password manually:"
			echo "mongo localhost/admin --eval 'db.getSiblingDB(\"dashboarddb\").createUser({user: \"$DB_USER\", pwd: \"YOUR_PASSWORD\", roles: [{role: \"readWrite\", db: \"dashboarddb\"}]})'"
		else
			/usr/bin/mongo localhost/admin --eval "db.getSiblingDB(\"dashboarddb\").createUser({user: \"$DB_USER\", pwd: \"$DB_PASSWORD\", roles: [{role: \"readWrite\", db: \"dashboarddb\"}]})"
		fi
	else
		echo "MongoDB is already present. Make sure you have setup the user and the password for the database"
	fi
#Installing java
yum install -y java-1.8.0-openjdk-devel

#Installing mvn
	if [[ ! -d /usr/local/src/apache-maven ]]
		then
		cd /usr/local/src
		yum install wget
		wget http://www-us.apache.org/dist/maven/maven-3/3.5.2/binaries/apache-maven-3.5.2-bin.tar.gz
		tar -xf apache-maven-3.5.2-bin.tar.gz
		rm -f apache-maven-3.5.2-bin.tar.gz
		mv apache-maven-3.5.2/ apache-maven/
echo "
# Apache Maven Environment Variables
# MAVEN_HOME for Maven 1 - M2_HOME for Maven 2
export M2_HOME=/usr/local/src/apache-maven
export PATH=${M2_HOME}/bin:${PATH}
" > /etc/profile.d/maven.sh
chmod +x /etc/profile.d/maven.sh
mvn --version

	else
		echo "Maven already present.."
	fi


#Install node js
	 if [[ $(rpm -qa | grep -c nodejs) -ne 1 ]]
		then
		curl --silent --location https://rpm.nodesource.com/setup_10.x | bash -
		yum clean expire-cache
		yum -y install nodejs
	else
		echo "Nodejs already exists...please make sure you have last version"
	fi


#Clone source
	if [ "$(ls -A $INSTALLPATH)" ]
		then
		echo "$INSTALLPATH not empty"
	else
        	su -c "git clone $GITSOURCE $INSTALLPATH" $USER
	fi


#Compile UI
echo "Compling source code. This might take a while.. time to have a coffe"
sleep 2

echo "
npm install gulp
npm install bower
npm install
bower install
mvn clean install package
" > $INSTALLPATH/UI/installUI.sh
chmod +x $INSTALLPATH/UI/installUI.sh
chown $USER $INSTALLPATH/UI/installUI.sh
cd $INSTALLPATH/UI/
su -c "./installUI.sh" $USER

echo "UI install done"


echo "
npm install gulp
npm install bower
npm install
bower install
mvn clean install package
" > $INSTALLPATH/install.sh
chmod +x $INSTALLPATH//install.sh
chown $USER $INSTALLPATH/install.sh
cd $INSTALLPATH
su -c "./install.sh" $USER

echo "Full install done"
