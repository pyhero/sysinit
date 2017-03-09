#!/bin/bash
#
# system init
# Author: Xu Panda
# Update: 2015-09-09

export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"
DIR=$(cd `dirname $0`;echo $PWD) && cd $DIR
init=/etc/init.d
output="/dev/null"
conf=./conf

## Install repos:
yum -q update centos-release -y;yum -q install epel-release -y;yum -q clean all;yum -q update -y

## Check local langure charset
if [ $(grep "^LANG=" /etc/sysconfig/i18n | awk -F '"' '{print $2}') != "en_US.UTF-8" ];then
	sed -ri '/^LANG=.*/ s//LANG="en_US.UTF-8"/' /etc/sysconfig/i18n
fi

## Use ntp to set time
yum -q install ntp ntpdate -y
/etc/init.d/ntpd stop > $output
ntpdate 0.asia.pool.ntp.org > $output
$init/ntpd start > $output && chkconfig ntpd on

## Disable selinux
if sestatus | grep enable;then
	setenforce 0 > /dev/null
	sed -ri '/^SELINUX=\w+$/ s//SELINUX=disabled/' /etc/selinux/config
fi

## Disable iptables
$init/iptables stop > $output;chkconfig iptables off

## tcp_tw
cat >> /etc/sysctl.conf << EOF
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_fin_timeout = 30
EOF
sysctl -p

## Install necessary software
yum install make cmake gcc python \
		tcpdump iftop sysstat bind-utils traceroute screen lrzsz xinetd rsync net-snmp-utils\
		openssl openssl-devel mhash mhash-devel compat-libstdc++-33 \
		libmcrypt libmcrypt-devel libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel pcre pcre-devel libevent libevent-devel \
		sl sipcalc \
		bash-completion jwhois tree \
		-y -q

## Shutdown unnecessary services
for p in $(chkconfig --list | awk '$1!~/aegis|xinetd|winbind|smb|ntpd|crond|snmpd|network|syslog|sshd|tunnel|psacct/ && $5~/on/ {print $1}');do
	$init/$p stop > $output
	chkconfig $p off
done

## Mkdir
root=/ROOT
[ ! -e $root ] && mkdir $root
cd $root
dir="www tmp server logs src BACKUP sh/CRON data conf bin"
for i in $dir;do
	mkdir -p $i
done
chmod 700 /ROOT/BACKUP
chmod 777 /ROOT/tmp && chmod o+t /ROOT/tmp
chmod 750 /ROOT/sh
if ! grep -q '/ROOT/bin' /etc/profile;then
	echo 'export PATH=/ROOT/bin:$PATH' >> /etc/profile
	source /etc/profile
fi
cd $DIR

## modify logrotate time to 23:59
if [ -f /etc/cron.daily/logrotate ];then
	mv /etc/cron.daily/logrotate /ROOT/sh/CRON
fi
crondir=/etc/cron.d
cat > $crondir/logrotate << EOF
# logrotate
59 23 * * * root sh /ROOT/sh/CRON/logrotate
EOF

## rsync bakup
sed -i '/disable/s/yes/no/' /etc/xinetd.d/rsync
$init/xinetd start > $output && chkconfig xinetd on

rsync -az BACKUP /ROOT/
cat > $crondir/snap << EOF
# snaphost backup
30 1 * * * root /ROOT/BACKUP/snapshot/snap.sh
EOF

cd BACKUP/rsync
sh ry.sh 
cd $DIR

## ssh keys for control
keyfile=$conf/authorized_keys && keydir=/root/.ssh
if [ ! -d $keydir ];then
	mkdir $keydir
	chmod -R 700 $keydir
fi
cp $keyfile $keydir

## kill updatedb
sed -i '2,$s/^/#/' /etc/cron.daily/mlocate.cron

## nf_conntrack: if someone run iptables -nvL,then maybe make a table_full err.
modprobe ip_conntrack
sysctl -w net.nf_conntrack_max=6553500 > $output
grep -q "net.nf_conntrack_max" /etc/sysctl.conf
if [ $? -ne 0 ];then
	echo "net.nf_conntrack_max = 6553500" >> /etc/sysctl.conf
fi

## dns resolv timeout
if ! grep -q 'options' /etc/resolv.conf;then
	sed -i '1ioptions timeout:5 attempts:1 rotate' /etc/resolv.conf
fi
if ! grep -q '172.16.0.' /etc/resolv.conf;then
	sed -i '/options/anameserver 172.16.0.1\nnameserver 172.16.0.2' /etc/resolv.conf  
fi

## add snmp keys post ser resolve
if ! grep 'post.aiuv.cc' /etc/hosts &> $output;then
cat >> /etc/hosts << EOF
10.170.236.206	post.aiuv.cc
EOF
fi

## tunnel
cd tunnel && sh mktun.sh
cd $DIR

## snmpv3
cd snmpv3 && sh install.sh
cd $DIR

## nrpe
sh plugin.sh && sh nrpe.sh

## iptables
sh iptables/gfw.sh

## ldap

echo -e "\n\e[32mDon't forget to reboot your system!\nRun:\n\nshutdown -r now\n\e[0m"
