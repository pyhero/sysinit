#! /bin/bash
# Snapshot important files everyday to /BACKUP/snapshot
#####################################################
# LOCATION : /ROOT/BACKUP/scripts/snapshot/snap.sh
# CRONTAB  : 30 2 * * * /ROOT/BACKUP/scripts/snapshot/snap.sh
# AUTHOR   : Xu Panda
# DATE     : 20150510
#####################################################
# CHANGE LOG
#

export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:"

RESERVE_COUNT=1
ROOT=/ROOT/BACKUP/snapshot
SCRIPT_DIR=$(cd $(dirname $0); pwd)

mkdir -p $ROOT
cd $ROOT

#*****************************************
# backup files
DAILY='daily'
EXCLUDES=${SCRIPT_DIR}/snap_exclude.list
FILES_FROM=${SCRIPT_DIR}/snap_files_from.list

if [ "$RESERVE_COUNT" -gt 1 ]; then
	DATE=`/bin/date -d '1 days ago' "+%Y-%m-%d"`;
	if [ ! -d $DATE ] ; then
		if [ -d $DAILY ] ; then
			echo -n Making yesterday snapshot...
			cp -al $DAILY $DATE ;
			echo done
		fi;
	fi
fi

echo -n Making today snapshot...
rsync 	--exclude-from="$EXCLUDES" 	 \
	-avr --delete --delete-excluded \
	--ignore-errors \
	--files-from="$FILES_FROM" 	 \
	/ $DAILY ;
echo done

touch $DAILY

OLD=`/bin/date -d "$RESERVE_COUNT days ago" "+%Y-%m-%d"`;
rm -rf $OLD ;

#*****************************************
# svn backup
#TODAY=`/bin/date "+%Y-%m-%d"`;
#FILE="$ROOT/svn/$TODAY.tar";
#if [ ! -f "$FILE.bz2" ]; then
#	touch $FILE
#
#	cd /ROOT/svn
#	for REPO in `ls`
#	do
#		if [ ! -d "$REPO" ]; then
#			continue
#		fi
#		echo SVN hotcopying $REPO
#		svnadmin hotcopy $REPO $ROOT/svn/$REPO
#		cd $ROOT/svn
#		tar -rf $FILE $REPO
#		rm -rf $ROOT/svn/$REPO
#		cd -
#	done
#	bzip2 $FILE
#fi
##OLD=`/bin/date -d "$RESERVE_COUNT days ago" "+%Y-%m-%d"`;
#OLD=`/bin/date -d "15 days ago" "+%Y-%m-%d"`;
#rm -rf $ROOT/svn/$OLD*
#
###!!!! EXIT !!!###
#exit
#
##*****************************************
## database backup
#innobackupex-1.5.1 --user=u --password=p --defaults-file=$ROOT/db/my.cnf --socket=/tmp/mysql.sock $ROOT/db/
#
#rm -rf $ROOT/db/$OLD*
#
#
##*****************************************
## backup all data to other disk
#ROOT=/BACKUP
#rsync -avr --delete $ROOT/ /ROOT/data/BACKUP
