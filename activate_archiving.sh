#!/bin/bash
# By Rupert
# Archive script to check for existence of archive directory, archive_active file, archive files

# Include directory paths from config file
DIRNAME=`dirname $0`
SOURCE=`pwd`
CONFIG=$SOURCE/$DIRNAME/config

. $CONFIG

touch $PGARCHIVE_TRIGGER_FILE
chown -Rf pgsql:pgsql $PGARCHIVE_TRIGGER_FILE
