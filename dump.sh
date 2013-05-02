#!/bin/bash
# Script that dump the database and show how many seconds it took

dbs=( db1 db2 db3 )

for db in "${dbs[@]}"
do
   begin_time=`date +%s`
   pg_dump --host=127.0.0.1 --port=5432 --username=pgsql --format=custom --file="./$db.backup" $db
   end_time=`date +%s`

   elapsed_time=`expr $end_time - $begin_time`

   echo "Dumping $db $elapsed_time seconds"
done
