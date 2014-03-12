#!/usr/bin/env bash
# By Rupert
# Recovers from a standalone base_backup (20130423062540.tar.gz)
# from the recovery dir (/var/db/pgsql_backup/)

# Include directory paths from config file
DIRNAME=`dirname $0`
SOURCE=`pwd`

CONFIG=$SOURCE/$DIRNAME/config

. $CONFIG

if [[ "$OSTYPE" == "linux-gnu" ]]; then
	PGINIT=/etc/init.d/postgresql
elif [[ "$OSTYPE" == "freebsd"* ]]; then
	PGINIT=/usr/local/etc/rc.d/postgresql
else
	PGINIT=/usr/local/etc/rc.d/postgresql
fi

BACKUPFILE=$1
RECOVERDIR=$PGBACKUP_DIR/$BACKUPFILE

recovery_conf(){
   mv $RECOVERDIR/recovery.local.conf $RECOVERDIR/pgsql/recovery.conf
}

if [ $# -eq 0 ]
then
   echo "usage: recover.sh [file]"
   echo "i.e: recover.sh 20130423072321"
   echo "Error: No BACKUPFILE specified. Please choose among:"
   echo "--------------------------------"
   ls $PGBACKUP_DIR/*.tar.gz
   exit 1;
fi

if [ -d $RECOVERDIR ]
then
   echo "Removing existing $RECOVERDIR"
   rm -Rf $RECOVERDIR
fi

echo "Extracting $BACKUPFILE.tar.gz..."
mkdir -p $RECOVERDIR
tar -zxf $PGBACKUP_DIR/$BACKUPFILE.tar.gz -C $RECOVERDIR

echo "Moving archive to pgsql/..."
mv $RECOVERDIR/archive $RECOVERDIR/pgsql/

echo "Moving recovery.conf to pgsql/..."
recovery_conf

echo "Creating pg_log and pg_xlog directories in pgsql.."
mkdir $RECOVERDIR/pgsql/pg_xlog
mkdir $RECOVERDIR/pgsql/pg_log

echo "Setting permissions to pgsql for $BACKUPFILE..."
chown -Rf pgsql:pgsql $RECOVERDIR/pgsql

echo "Stopping postgres..."
${PGINIT} stop

echo "Moving current pgsql to pgsql.old. Its good to have a backup of what happened"
mv $PGDATA $PGDATA.old

echo "Moving $RECOVERDIR/pgsql to $PGPARENT"
mv $RECOVERDIR/pgsql $PGPARENT/

echo "------------------------------------"
echo "Ok we are ready. Lets rock!"
echo "To recover, you need to start postgresql manually. "
echo ""
echo "Successful recovery can be verified by:"
echo "a. Checking for recovery.done in pgsql/"
echo "b. Checking for backup_label.old in pgsql/"
echo "c. tail -f pg_log/logfile"
echo "------------------------------------"

exit 0;
