#!/bin/bash
#set -x



#Var
PATH=$PATH:/usr/local/src/apache-maven/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/centos/.local/bin:/home/centos/bin

DISK=$1
INSTALLPATH=/usr/local/src/hygieia
USER=hygieia
VGNAME=vghygieia
LVNAME=lvhygieia
GITSOURCE="https://github.com/capitalone/Hygieia.git"


disksize() { 

pvdisplay /dev/$DISK | grep "PV Size" | awk '{print $3}' | awk -F '.' '{print $1}'
}

#Create mount point
	if [[ $(grep -c $LVNAME /etc/mtab) -eq 0 ]]
		then
		echo "Creating filesystem for Hygiei"
		mkdir -p -m 400 $INSTALLPATH 
		pvcreate /dev/$DISK
		PVSIZE=$(( $(disksize) - 1 ))
		vgcreate $VGNAME /dev/$DISK
		lvcreate -L "$PVSIZE"G -n $LVNAME /dev/$VGNAME
		mkfs.ext4 /dev/$VGNAME/$LVNAME
		echo "/dev/mapper/$VGNAME-$LVNAME $INSTALLPATH ext4 defaults 1 2" >> /etc/fstab
		mount -a
		RC=$(echo $?)
		echo $RC
		if [[ $RC -eq 0 ]]
			then
			echo "File-system mounted"
		else
			"ERROR..I could not mount the file-system"
		fi
	else
		echo "File-system already exist"
	fi

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
		/usr/bin/mongo localhost/admin  --eval 'db.getSiblingDB("dashboarddb").createUser({user: "dashboarduser", pwd: "dbpassword", roles: [{role: "readWrite", db: "dashboarddb"}]})'
	else
		echo "MongoDB is alreay present. Make sure you have setup the use and the password for the database"
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
