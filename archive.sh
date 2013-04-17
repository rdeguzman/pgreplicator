#!/bin/sh
# By Rupert
# Archive script to check for existence of archive directory, archive_active file, archive files

# Include directory paths from config file
DIRNAME=`dirname $0`
SOURCE=`pwd`
CONFIG=$SOURCE/$DIRNAME/config

. $CONFIG
source_file=$1
dest_file=$2

local(){
   echo "`date`: Local: Copying $source_file to $PGARCHIVE_DIR/$dest_file..."

   if [ -f $PGARCHIVE_DIR/$dest_file ]
   then
      echo "`date`: Archive file $dest_file already exists"
      exit 1
   else
      cp -i $source_file $PGARCHIVE_DIR/$dest_file
      exit 0
   fi
}

remote_ssh(){
   echo "`date`: Remote SSH: Copying $source_file to $ARCHIVE_USER@$ARCHIVE_SERVER:$PGARCHIVE_DIR..."
   scp -P $ARCHIVE_SERVER_SSH_PORT $source_file $ARCHIVE_USER@$ARCHIVE_SERVER:$PGARCHIVE_DIR
   if [ $? -ne 0 ];then
      echo "`date`: SCP failed"
      exit 1
   else
      exit 0
   fi
}

remote_rsync(){
   echo "Remote"
}

process(){
   case "$PGARCHIVE_MODE" in
      0)
         local
         ;;
      1)         
         remote_ssh
         exit 0
         ;;
      *)
         echo "`date`: Please set the archive mode"
         exit 1
         ;;
   esac
}

if [ -d $PGBACKUP_DIR ] && [ -d $PGARCHIVE_DIR ]
then
   if [ -f $PGARCHIVE_TRIGGER_FILE ]
   then
      echo "`date`: Found $PGARCHIVE_TRIGGER_FILE. Archiving Active."
      process
   else
      echo "`date`: Archiving Inactive."
      exit 0
   fi
else
   echo "`date`:$PGBACKUP_DIR or $PGARCHIVE_DIR not found"
   exit 1
fi
