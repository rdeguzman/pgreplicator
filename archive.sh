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

archive_locally(){
   echo "`date`: Archive Locally: cp $source_file $PGARCHIVE_DIR/$dest_file"

   if [ -f $PGARCHIVE_DIR/$dest_file ]
   then
      echo "`date`: Archive file $dest_file already exists"
      exit 1
   else
      cp -i $source_file $PGARCHIVE_DIR/$dest_file
   fi
}

archive_ssh(){
   echo "`date`: $4 via Remote SSH: cp $source_file $2@$3:$PGARCHIVE_DIR"
   scp -P $1 $source_file $2@$3:$PGARCHIVE_DIR
   if [ $? -ne 0 ];then
      echo "`date`: SCP failed"
      exit 1
   else
   fi
}

process_archive(){
   case "$PGARCHIVE_MODE" in
      0)
         archive_locally
         ;;
      1)         
         archive_ssh $ARCHIVE_SERVER_SSH_PORT $ARCHIVE_USER $ARCHIVE_SERVER "Archive"
         ;;
      2)         
         archive_locally
         archive_ssh $ARCHIVE_SERVER_SSH_PORT $ARCHIVE_USER $ARCHIVE_SERVER "Archive"
         ;;
      *)
         echo "`date`: Please set the archive mode"
         exit 1
         ;;
   esac
}

process_standby(){
   echo $PGSTANDBY_ENABLED
   if [ $PGSTANDBY_ENABLED = "1" ]
   then
      archive_ssh $STANDBY_SERVER_SSH_PORT $STANDBY_USER $STANDBY_SERVER "Standby"
   fi
}

if [ -d $PGBACKUP_DIR ] && [ -d $PGARCHIVE_DIR ]
then
   if [ -f $PGARCHIVE_TRIGGER_FILE ]
   then
      echo "`date`: Found $PGARCHIVE_TRIGGER_FILE. Archiving Active."
      process_archive
      process_standby
      exit 0
   else
      echo "`date`: Archiving Inactive."
      exit 0
   fi
else
   echo "`date`:$PGBACKUP_DIR or $PGARCHIVE_DIR not found"
   exit 1
fi
