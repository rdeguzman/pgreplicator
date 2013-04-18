#!/bin/sh
# By Rupert
# Backup script which automates archiving, taking a base backup then stopping the archiving

# Include directory paths from config file
DIRNAME=`dirname $0`
SOURCE=`pwd`
CONFIG=$SOURCE/$DIRNAME/config

. $CONFIG

echo "Archiving active..."
touch $PGARCHIVE_TRIGGER_FILE

echo "Start basebackup..."
psql -d postgres -U pgsql -c "select pg_start_backup('pgsql_backup'), current_timestamp"

tar -cv --exclude=pg_xlog --exclude=pg_log -f $PGBACKUP_DIR/backup.tar $PGDATA/

echo "Stop basebackup..."
psql -d postgres -U pgsql -c "select pg_stop_backup(), current_timestamp"

echo "Removing trigger file..."
rm $PGARCHIVE_TRIGGER_FILE

echo "Adding $PGARCHIVE_DIR to backup.tar"
tar -rf $PGBACKUP_DIR/backup.tar $PGARCHIVE_DIR
