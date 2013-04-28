#!/bin/sh
# By Rupert
# Creates a standalone base_backup and WAL segments into 20130423062540.tar.gz
# The compressed base backup has a directory structure of
#
# 20130423062540.tar.gz
#  pgsql/
#  archive/ 

# Include directory paths from config file
DIRNAME=`dirname $0`
SOURCE=`pwd`
CONFIG=$SOURCE/$DIRNAME/config

. $CONFIG

echo "Creating $PGARCHIVE_TRIGGER_FILE. Archiving active..."
touch $PGARCHIVE_TRIGGER_FILE

echo "Starting basebackup..."
psql -d postgres -U pgsql -c "select pg_start_backup('pgsql_backup'), current_timestamp"

echo "Tar pgsql dir to $PGBACKUP_DIR/$PGBACKUP_FILE.tar..."
tar -c --exclude=pg_xlog --exclude=pg_log -f $PGBACKUP_DIR/$PGBACKUP_FILE.tar -C $PGPARENT $PGDIR/

echo "Stopping basebackup..."
psql -d postgres -U pgsql -c "select pg_stop_backup(), current_timestamp"

echo "Removing $PGARCHIVE_TRIGGER_FILE. Archiving inactive..."
rm $PGARCHIVE_TRIGGER_FILE

echo "Adding $PGARCHIVE_DIR to $PGBACKUP_FILE.tar"
tar -rf $PGBACKUP_DIR/$PGBACKUP_FILE.tar -C $PGBACKUP_DIR archive

echo "Removing WAL segments from archive directory..."
#rm -Rf $PGARCHIVE_DIR/*

echo "Creating recovery.conf..."
cp $PGSCRIPTS_DIR/recovery.local.conf .
tar -rf $PGBACKUP_DIR/$PGBACKUP_FILE.tar recovery.local.conf
rm recovery.local.conf

echo "Compressing $PGBACKUP_DIR/$PGBACKUP_FILE.tar..."
gzip $PGBACKUP_DIR/$PGBACKUP_FILE.tar
