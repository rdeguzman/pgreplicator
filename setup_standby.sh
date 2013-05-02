#!/bin/bash
# By Rupert
# This script should run on a standby server only

# Include directory paths from config file
DIRNAME=`dirname $0`
SOURCE=`pwd`
CONFIG=$SOURCE/$DIRNAME/config

. $CONFIG

echo "Copying postgresql.slave.conf"
mv $PGDATA/postgresql.conf $PGDATA/postgresql.conf.old
cp $PGSCRIPTS_DIR/postgresql.slave.conf $PGDATA/postgresql.conf

echo "Copying recovery.slave.conf"
cp $PGSCRIPTS_DIR/recovery.slave.conf $PGDATA/recovery.conf

if [ -d $PGDATA/pg_xlog ]
then
   echo "Removing existing pg_xlog"
   rm -rf $PGDATA/pg_xlog
fi

echo "Creating pg_xlog"
mkdir $PGDATA/pg_xlog

echo "Setting ownership to pgsql:pgsql"
chown -Rf pgsql:pgsql $PGDATA/postgresql.conf $PGDATA/recovery.conf $PGDATA/pg_xlog

echo "Change password from recovery.conf"
grep -rn "primary_conninfo" $PGDATA/recovery.conf
