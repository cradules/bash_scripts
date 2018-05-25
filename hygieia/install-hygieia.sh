#!/bin/bash
#set -x



#Var
export PATH=/bin:/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/src/apache-maven/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/centos/.local/bin:/home/centos/bin

DISK=$1
INSTALLPATH=/usr/local/src/hygieia
USER=hygieia
VGNAME=vghygieia
LVNAME=lvhygieia
GITSOURCE="https://github.com/capitalone/Hygieia.git"
ENCRYPTORPASSWORD="hygieiasecret"
CDISK=$(ls -al /dev/ | grep -c $DISK 2> /dev/null) 
MVNURL="http://apache.javapipe.com/maven/maven-3/3.1.1/binaries/apache-maven-3.1.1-bin.tar.gz"
HRELEASE="https://github.com/capitalone/Hygieia/archive/Hygieia-2.0.4.tar.gz"

mvntar() {
MVNTAR=$(ls -al | grep maven | awk '{print $9}')
}

fld(){
FLD=$(ls -al | grep maven | awk '{print $9}' | grep "tar.gz" | awk -F '-' '{print $1"-"$2"-"$3}')
}


disksize() { 

pvdisplay /dev/$DISK | grep "PV Size" | awk '{print $3}' | awk -F '.' '{print $1}'
}
#Check user
	if [[ $EUID -ne 0 ]]
		then 
		echo "This script must be run as root!" 
		exit 1
	fi 
#Check argument

	if [[ $# -ne 1 && $1 != "nodisk" ]]
		then
		echo "Usage : $0 <disk-name>|nodisk"
		echo "disk-name = a free present disk"
		echo "nodisk = the install will not me made on an individual file-system"
		exit 1
	fi
	if [[ $CDISK -eq 0 && $1 != "nodisk" ]]
		then
		echo "Disk not found"
		exit 1
	fi
#Create user
id $USER &> /dev/null
RC=$(echo $?)
        if [[ $RC -ne 0 ]]
                then
                echo "Adding user $USER"
                adduser $USER
                #Setting owner and permisions

        else
                echo "User $USER already exist"
        fi


#Create mount point
	if [[ $(grep -c $LVNAME /etc/mtab) -eq 0 && $CDISK -eq 1 ]]
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
			chown $USER:$USER $INSTALLPATH
			echo "File-system mounted"
		else
			"ERROR..I could not mount the file-system"
		fi
	fi

#Needfull
yum -y install git
yum -y install bzip2
yum -y install net-tools
yum -y install iptables-services


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
#Install bower
/usr/bin/npm install -g bower
/usr/bin/npm install -g gulp

#Installing mvn
	if [[ ! -d /usr/local/src/apache-maven ]]
		then
		cd /usr/local/src
		yum -y install wget
		wget $MVNURL 
		mvntar
		fld
		tar -xf $MVNTAR
		mv $FLD apache-maven/
		rm -f $MVNTAR
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
		curl --silent --location https://rpm.nodesource.com/setup_8.x | sudo bash -
		yum clean expire-cache
		yum -y install nodejs
	else
		echo "Nodejs already exists...please make sure you have last version"
	fi


#Download source

	if [[ $1 = "nodisk" ]]
		then	
		if [[ -d $INSTALLPATH || $(ls -A $INSTALLPATH) ]]
			then
			echo "$INSTALLPATH not empty"
			exit 1
		else
			cd /usr/local/src
			wget $HRELEASE
			HYTAR=$(ls -al | grep Hygieia | grep "tar.gz" | awk '{print $9}')
			tar -xf $HYTAR
			HYGIEIA=$(ls -al | grep Hygieia | grep -v "tar.gz" | awk '{print $9}')
			mv $HYGIEIA hygieia 
			rm -f $HYTAR
			#Setup binary
			mkdir -p $INSTALLPATH/bin
			chown -R $USER:$USER $INSTALLPATH
		fi
	else
		cd $INSTALLPATH
		wget $HRELEASE
		HYTAR=$(ls -al | grep Hygieia | grep "tar.gz" | awk '{print $9}')
		tar -xf $HYTAR
		HYGIEIA=$(ls -al | grep Hygieia | grep -v "tar.gz" | awk '{print $9}')
		cd $HYGIEIA
		mv * ..; cd ..
		rmdir $HYGIEIA; rm -f $HYTAR
		chown -R $USER:$USER $INSTALLPAT
		
		
		

	fi

#Compile UI
echo "Compling source code. This might take a while.. time to have a coffe"
sleep 2

echo "
/usr/bin/npm install gulp
/usr/bin/npm install  bower
/usr/bin/npm install browser-sync
/usr/bin/npm install
bower install
mvn clean install package
" > $INSTALLPATH/UI/installUI.sh
chmod +x $INSTALLPATH/UI/installUI.sh
chown $USER $INSTALLPATH/UI/installUI.sh
cd $INSTALLPATH/UI/
su -c "./installUI.sh" $USER
rm -f ./installUI.sh

echo "UI install done"


echo "
/usr/bin/npm install gulp
/usr/bin/npm install bower
/usr/bin/npm install
bower install
/usr/bin/npm install browser-sync
mvn clean install package
" > $INSTALLPATH/install.sh
chmod +x $INSTALLPATH//install.sh
chown $USER $INSTALLPATH/install.sh
cd $INSTALLPATH
su -c "./install.sh" $USER
rm -f ./install.sh

echo "Full install done"


#Configure api.properties

echo "
# api.properties
dbname=dashboarddb
dbusername=dashboarduser
dbpassword=dbpassword
dbhost=localhost
dbport=27017
dbreplicaset=false
#dbhostport=[host1:port1,host2:port2,host3:port3]
#server.contextPath=[Web Context path, if any]
server.port=8080
logRequest=false
logSplunkRequest=false
corsEnabled=false
#corsWhitelist=http://domain1.com:port,http://domain2.com:port
version.number=@application.version.number@

#auth.expirationTime=[JWT expiration time in milliseconds]
#auth.secret=[Secret Key used to validate the JWT tokens]
auth.authenticationProviders=STANDARD
#auth.ldapServerUrl=[LDAP Server URL, including port of your LDAP server]
#auth.ldapUserDnPattern=[LDAP User Dn Pattern, where the username is replaced with '{0}']
" > $INSTALLPATH/api/api.properties
chown $USER:$USER $INSTALLPATH/api/api.properties

#Create UI start
echo "npm install gulp" > $INSTALLPATH/UI/startui.sh
echo "gulp serve &" >> $INSTALLPATH/UI/startui.sh
chmod +x $INSTALLPATH/UI/startui.sh
chown  $USER $INSTALLPATH/UI/startui.sh

#Create API start
echo "java -jar $INSTALLPATH/UI/target/api.jar --spring.config.location=$INSTALLPATH/api/api.properties -Djasypt.encryptor.password=$ENCRYPTORPASSWORD " > $INSTALLPATH/api/startapi.sh
chmod +x $INSTALLPATH/api/startapi.sh
chown $USER:$USER $INSTALLPATH/api/startapi.sh

