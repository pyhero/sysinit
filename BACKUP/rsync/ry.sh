#!/bin/bash
#
# Add backup rsync dir

dir=$(cd `dirname $0`;echo $PWD)

drf=/etc/rsyncd.conf
srf=$dir/rsyncd.conf

if [ -f $drf ];then
cat >> $drf << EOF

[BACKUP]
path            = /ROOT/BACKUP/snapshot
hosts allow     = 172.16.0.9
read only       = no
EOF
else
	rsync -avz $srf $drf > /dev/null
fi

/etc/init.d/xinetd restart > /dev/null
