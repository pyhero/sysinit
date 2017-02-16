#!/bin/bash

DIR=$(cd `dirname $0`;echo $PWD)
PK="$DIR/soft/*.rpm"
yum -q --nogpgcheck -y install $PK

if ! grep -q 'notConfigUser' /etc/snmp/snmpd.local.conf;
then
cat >> /etc/snmp/snmpd.local.conf << EOF
com2sec notConfigUser default PaxX2099clv2
group mygroup v2c notConfigUser
EOF
fi

if ! grep -q 'smuxpeer' /etc/snmp/snmpd.conf;
then
cat >> /etc/snmp/snmpd.conf << EOF
view    all             included        .1
smuxpeer .1.3.6.1.4.1.674.10892.1
EOF
fi

sed -i '/^access/s/systemview/all/' /etc/snmp/snmpd.conf

/etc/init.d/snmpd restart
