#!/bin/bash
#####################################################
# LOCATION : /ROOT/BACKUP/scripts/backup.sh
# CRONTAB  : 0 4 * * * /ROOT/BACKUP/scripts/backup.sh
# AUTHOR   : Xu Panda
# DATE     : 20150510
#####################################################
export PATH="/usr/bin:/usr/sbin:/bin:/sbin"

loglog() {
	echo [`date`] $@
}

BACKUP_ROOT="/ROOT/BACKUP/warehouse"
DIR_EXEC=`dirname $0`

while read HOST RPATH
do
	export PATH="/usr/bin:/usr/sbin:/bin:/sbin"
	if `echo $HOST | grep -q '#'`; then
		echo ignore $HOST
		continue
	fi

	echo
	loglog '*************************************'
	echo [`date`] start $HOST:$RPATH
	mkdir -p $BACKUP_ROOT/$HOST
	cd $BACKUP_ROOT/$HOST

	YESTERDAY=`date -d '1 days ago' "+%Y-%m-%d"`
	MODS="daily svn mysql"
    for MOD in $MODS; do
		if [ -d "$MOD" ]; then
			if [ -d "$MOD.$YESTERDAY" ]; then
				echo [`date`] "Yesterday's [$MOD] snapshot has already been archived. Only sync today."
			else
				loglog [$MOD] making yesterday
				cp -la $MOD $MOD.$YESTERDAY
			fi
		fi
	done

	loglog rsync -avz --delete $HOST::$RPATH .
	rsync -avz --delete $HOST::$RPATH .

	loglog "find . -maxdepth 1 -mtime +30 -print0 | xargs -0 -n1 rm -rf"
	find . -maxdepth 1 -mtime +30 -print0 | xargs -0 -n1 rm -rf
	echo [`date`] end $HOST

	echo
	cd -
done < "$DIR_EXEC/config"

#rsync -avz --delete -H $BACKUP_ROOT 10.9.1.245::BACKUP/
