#!/usr/bin/env bash
# By Rupert
# Initializes backup directory
DIRNAME=`dirname $0`
SOURCE=`pwd`
CONFIG=$SOURCE/$DIRNAME/config
. $CONFIG

echo "Creating $PGBACKUP_DIR..."
mkdir -p $PGBACKUP_DIR
mkdir -p $PGARCHIVE_DIR

echo "Setting permissions to ${PGUSER}:${PGGROUP} for pgsql_backup..."
chown -Rf ${PGUSER}:${PGGROUP} $PGBACKUP_DIR
