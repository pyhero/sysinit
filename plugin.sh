#!/bin/bash
#

ROOT=$(cd `dirname $0`;echo $PWD)
SRC=$ROOT/src
CONF=$ROOT/conf
SCRIPT=$ROOT/script
WORK="/ROOT/server/nagios"

loip=$(ip a | grep inet | grep -v inet6 | grep -v "127\.0\.0\.1" | \
	egrep '(192\.168\.[0-9]*\.[0-9]*|10\.[0-9]*\.[0-9]*\.[0-9]*|172\.16\.[0-9]*\.[0-9]*)' | \
	awk '{print $2}' | awk -F '/' '{print $1}')

download () {
	# You need to temm me url=? & name=? first.
	#url=
	# Name is the software packet.
	#name=
	if [ ! -f $file ];then
	/usr/bin/wget -q $url -O $SRC/$name
	fi
}

check_dir () {
	# You need to tell me dir=? first.
	#dir=
	if [ ! -d $dir ];then
		mkdir -p $dir
	fi
}

# Install Dependency.
echo -e "\n\e[31mInstall dependency: ...\e[0m"
yum -q install httpd php gcc glibc glibc-common gd gd-devel -y
id nagios &> /dev/null
if [ $? -ne 0 ];then
	groupadd -g 700 nagios && useradd -u 700 -g 700 -s /sbin/nologin nagios
fi


echo -e "\n\e[31mInstall nagios plugins: ...\e[0m"
plugin="nagios-plugins-2.0.3.tar.gz"
file=$SRC/$plugin
name=$plugin
url="http://nagios-plugins.org/download/nagios-plugins-2.0.3.tar.gz"
download

cd $SRC && tar zxf $plugin > /dev/null && cd nagios-plugins-2.0.3
./configure --prefix=$WORK --with-nagios-user=nagios --with-nagios-group=nagios > /dev/null && \
	make > /dev/null && \
	make install > /dev/null
cd $ROOT
