#!/bin/sh
# By Rupert
# This script should run on a standby server only

# Include directory paths from config file
DIRNAME=`dirname $0`
SOURCE=`pwd`
CONFIG=$SOURCE/$DIRNAME/config

. $CONFIG

echo "Copying postgresql.slave.conf"
mv postgresql.conf postgresql.conf.old
mv $PGSCRITPS_DIR/postgresql.slave.conf postgresql.conf

if [ -d pg_xlog ]
then
   echo "Removing existing pg_xlog"
   rm -rf pg_xlog
fi

echo "Creating pg_xlog"
mkdir pg_xlog

echo "Setting ownership to pgsql:pgsql"
chown -Rf pgsql:pgsql postgresql.conf recovery.conf pg_xlog
