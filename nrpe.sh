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

loip=$(echo $loip | sed 's/\n/ /')

download () {
	# You need to temm me url=? & name=? first.
	#url=
	# Name is the software packet.
	#name=
	if [ ! -f $file ];then
	/usr/bin/wget $url -O $SRC/$name > /dev/null
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
yum install httpd php gcc glibc glibc-common gd gd-devel -y > /dev/null

# Install nrpe
echo -e "\n\e[31mInstall nrpe: ...\e[0m"
nrpe="nrpe-2.15.tar.gz"
file=$SRC/$nrpe
name=$nrpe
url="http://sourceforge.net/projects/nagios/files/nrpe-2.x/nrpe-2.15/nrpe-2.15.tar.gz/download"
download
cd $SRC && tar zxf $nrpe && cd nrpe-2.15

# nrpe length output:
sed -i '/define MAX_CHARS/s/1024/4096/' contrib/nrpe_check_control.c
sed -i '/define MAX_INPUT_BUFFER/s/2048/4096/;/define MAX_PACKETBUFFER_LENGTH/s/1024/4096/' include/common.h
sed -i '/char buf/s/1000/4096/' src/check_nrpe.c
sed -i '/char buf/s/1024/4096/' src/snprintf.c 

./configure --prefix=$WORK > /dev/null && \
	make > /dev/null && \
	make install > /dev/null && \
	make install-daemon-config > /dev/null

cat > /etc/xinetd.d/nrpe << EOF
service nrpe
{
	flags           = REUSE
	socket_type     = stream
	wait            = no
	user            = nagios
	server          = $WORK/bin/nrpe
	server_args     = -c $WORK/etc/nrpe.cfg --inetd
	log_on_failure  += USERID
	disable         = no
	only_from       = 127.0.0.1 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16
}
EOF
grep -q -i nrpe /etc/services &> /dev/null
if [ $? -ne 0  ];then
	echo "nrpe            5666/tcp                # nrpe" >> /etc/services
fi
/etc/init.d/xinetd restart > /dev/null
cd $ROOT
