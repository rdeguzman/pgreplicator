#!/bin/sh
# By Rupert
# Recovers from a standalone base_backup (20130423062540.tar.gz)
# from the recovery dir (/var/db/pgsql_backup/)

# Include directory paths from config file
DIRNAME=`dirname $0`
SOURCE=`pwd`
CONFIG=$SOURCE/$DIRNAME/config

. $CONFIG

BACKUPFILE=$1
RECOVERDIR=$PGBACKUP_DIR/$BACKUPFILE

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

echo "Moving archive and recovery.conf to pgsql/..."
mv $RECOVERDIR/archive $RECOVERDIR/pgsql/
mv $RECOVERDIR/recovery.conf $RECOVERDIR/pgsql/

echo "Creating pg_log and pg_xlog directories in pgsql.."
mkdir $RECOVERDIR/pgsql/pg_xlog
mkdir $RECOVERDIR/pgsql/pg_log

echo "Setting permissions to pgsql for $BACKUPFILE..."
chown -Rf pgsql:pgsql $RECOVERDIR/pgsql

echo "Stopping postgres..."
/usr/local/etc/rc.d/postgresql stop

echo "Moving current pgsql to pgsql.old. Its good to have a backup of what happened"
mv $PGDATA $PGDATA.old

echo "Moving $RECOVERDIR/pgsql to $PGPARENT"
mv $RECOVERDIR/pgsql $PGPARENT/

echo "------------------------------------"
echo "Ok we are ready. Lets rock!"
echo "Starting postgresql..."
/usr/local/etc/rc.d/postgresql start

if [ -f $PGDATA/recovery.done ]
then
   echo "Recovery done!"
   echo "You can verify this by:"
   echo "a. Checking for recovery.done in pgsql/"
   echo "b. Checking for backup_label.old in pgsql/"
   echo "c. tail -f pg_log/logfile"
fi

exit 0;
