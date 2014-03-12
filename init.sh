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

if [[ "$OSTYPE" == "linux-gnu" ]]; then
        PGUSER="postgres"
	PGGROUP="postgres"
elif [[ "$OSTYPE" == "freebsd"* ]]; then
	PGUSER="pgsql"
	PGGROUP="pgsql"
else
	PGUSER="pgsql"
	PGGROUP="pgsql"
fi

echo "Setting permissions to ${PGUSER}:${PGROUGP} for pgsql_backup..."
chown -Rf ${PGUSER}:${PGGROUP} $PGBACKUP_DIR
