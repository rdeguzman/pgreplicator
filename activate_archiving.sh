#!/usr/bin/env bash
# By Rupert
# Activates archiving by creating a file 

# Include directory paths from config file
DIRNAME=`dirname $0`
SOURCE=`pwd`
CONFIG=$SOURCE/$DIRNAME/config

. $CONFIG

touch $PGARCHIVE_TRIGGER_FILE
chown -Rf pgsql:pgsql $PGARCHIVE_TRIGGER_FILE
