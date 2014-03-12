#!/usr/bin/env bash
# By Rupert
# This script should setup a standby server by preparing postgresql.con and recovery.conf

# Include directory paths from config file
DIRNAME=`dirname $0`
SOURCE=`pwd`
CONFIG=$SOURCE/$DIRNAME/config

. $CONFIG

echo "Copying postgresql.slave.conf"
mv $PGDATA/postgresql.conf $PGDATA/postgresql.conf.old
cp $PGCONF_DIR/postgresql.slave.conf $PGDATA/postgresql.conf

echo "Copying recovery.slave.conf"
cp $PGCONF_DIR/recovery.slave.conf $PGDATA/recovery.conf

if [ -d $PGDATA/pg_xlog ]
then
   echo "Removing existing pg_xlog"
   rm -rf $PGDATA/pg_xlog
fi

echo "Creating pg_xlog"
mkdir $PGDATA/pg_xlog

echo "Setting ownership to pgsql:pgsql"
chown -Rf ${PGUSER}:${PGGROUP} $PGDATA/postgresql.conf $PGDATA/recovery.conf $PGDATA/pg_xlog

echo "Change password from recovery.conf"
grep -rn "primary_conninfo" $PGDATA/recovery.conf
