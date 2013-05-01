#!/usr/localbin/bash
# By Rupert
# Syncs a base_backup from master to standby

# Include directory paths from config file
DIRNAME=`dirname $0`
SOURCE=`pwd`
CONFIG=$SOURCE/$DIRNAME/config

. $CONFIG

echo "Creating $PGARCHIVE_TRIGGER_FILE. Archiving active..."
touch $PGARCHIVE_TRIGGER_FILE

echo "Starting basebackup..."
psql -d postgres -U pgsql -c "select pg_start_backup('pgsql_backup'), current_timestamp"

echo "Sync rsync -a $PGDATA/ $STANDBY_USER@$STANDBY_SERVER:$PGDATA/ --exclude postmaster.pid --exclude pg_log"
rsync -a $PGDATA/ root@$STANDBY_SERVER:$PGDATA/ --exclude postmaster.pid --exclude pg_log --exclude pg_xlog

echo "Stopping basebackup..."
psql -d postgres -U pgsql -c "select pg_stop_backup(), current_timestamp"

echo "Removing $PGARCHIVE_TRIGGER_FILE. Archiving inactive..."
rm $PGARCHIVE_TRIGGER_FILE

echo "--------------IMPORTANT-------------------------"
echo "Please run setup_standby.sh on the standby server"...
