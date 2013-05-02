#!/bin/bash
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

recovery_conf(){
   case "$RECOVERY_MODE" in
      0)
         mv $RECOVERDIR/recovery.local.conf $RECOVERDIR/pgsql/recovery.conf
         ;;
      1)         
         mv $RECOVERDIR/recovery.standby.conf $RECOVERDIR/pgsql/recovery.conf
         ;;
      *)
         echo "`date`: Please set the recovery mode"
         ;;
   esac
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
/usr/local/etc/rc.d/postgresql stop

echo "Moving current pgsql to pgsql.old. Its good to have a backup of what happened"
mv $PGDATA $PGDATA.old

echo "Moving $RECOVERDIR/pgsql to $PGPARENT"
mv $RECOVERDIR/pgsql $PGPARENT/

if [ $RECOVERY_MODE = "0" ];then
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
else
   echo "------------------------------------"
   echo "It appears that recovery is not local. You might need to edit postgresql.conf "
   echo "and do a manual start of postgresql"
fi

exit 0;
