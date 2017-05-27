#This script is updateing the ports to http conf
set -x
OWNER=$1
CAM=$2
APP=$3

#getconfs
HTTPDIR="/etc/httpd/conf.d"
CONF=$(ls /etc/httpd/conf.d | grep $OWNER | grep $CAM)

#Get Ports
OLDPORT=$(grep -w ProxyPass  $HTTPDIR/$CONF | awk -F ':' '{print $3}' | tr -d '/')
NEWPORT=$(docker ps  | grep $OWNER | grep $CAM | grep $APP| awk '{print $12}' | awk -F ':' '{print $2}' | awk -F '-' '{print $1}' | grep -v "^$")


#Update port
sed -i "s/$OLDPORT/$NEWPORT/g" $HTTPDIR/$CONF

systemctl restart httpd

#echo $OLDPORT
#echo $NEWPORT
#echo $CONF


