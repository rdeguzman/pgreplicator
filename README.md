# PostgreSQL Scripts

The scripts below are used to setup archiving in Postgres9.x on FreeBSD9.1

## Prerequisites

#### Passwordless SCP

Note that you need to generate ssh keys across both servers so scp will not ask for a password.

On the **master** server:

	# su -l pgsql
	# cd /usr/local/pgsql
	# mkdir .ssh
	# ssh-keygen -t rsa
	…
	# cp id_rsa.pub master.pub
	# scp master.pub root@destination:/usr/local/pgsql/
	

This will generate id_rsa and id_rsa.pub. Do not remove id_rsa on master. Transfer id_rsa.pub to the destination server and include it in it's authorized_keys

On the **archive** server:

	# su -l pgsql
	# cd /usr/local/pgsql
	# mkdir .ssh
	# cat master.pub >> .ssh/authorized_keys
	
Test by copying a file from **master** to **archive** using scp

	scp foo pgsql@archive_server:/usr/local/pgsql/


## Grab the scripts

1. Clone

		# cd /var/db
		# git clone https://github.com/rdeguzman/pgreplicator.git

2. Create initial directories
		
		# pgreplicator/init.sh
		
3. Adjust configurations in config file

		# cat pgreplicator/config
		PGDATA="/var/db/pgsql"
		PGBACKUP_DIR="/var/db/pgsql_backup"
		PGARCHIVE_DIR=$PGBACKUP_DIR/archive
		PGARCHIVE_TRIGGER_FILE=$PGBACKUP_DIR/archiving_active
		….
	
## Backup Setup

### Local Archiving

Archives WAL segments to a local directory as specified in

* $ARCHIVE_DIR
* PGARCHIVE_MODE="0"

### Remote Archiving via SSH
Archives WAL segments to a remote server as specified in:

* $ARCHIVE_DIR
* $ARCHIVE_USER - normally this is pgsql
* ARCHIVE_SERVER
* ARCHIVE_SERVER_SSH_PORT
* PGARCHIVE_MODE="1"

### Performing a base backup

1. Enable archiving

		# See postgresql.master.conf
		archive_mode = on # allows archiving to be done
		archive_command = '../pgreplicator/archive.sh %p %f'
		archive_timeout = 30
		
 	Change requires a postgresql restart
 	
 		# /usr/local/etc/rc.d/postgresql stop
		# /usr/local/etc/rc.d/postgresql start
 		
2. Run **base_backup.sh**

		# cd /var/db/pgreplicator
		# ./base_backup.sh
		Creating /var/db/pgsql_backup/archiving_active. Archiving active...
		Starting basebackup...
		 pg_start_backup |              now
		-----------------+-------------------------------
		 6/BA000020      | 2013-05-01 19:00:29.932488+00
		(1 row)

		Tar pgsql dir to /var/db/pgsql_backup/20130502050029.tar...
		Stopping basebackup...
		NOTICE:  pg_stop_backup complete, all required WAL segments have been archived
		 pg_stop_backup |              now
		----------------+-------------------------------
		 6/BB000048     | 2013-05-01 19:01:22.096923+00
		(1 row)

		Adding /var/db/pgsql_backup/archive to 20130502050029.tar
		Removing WAL segments from archive directory...
		Creating recovery.conf...
		Compressing /var/db/pgsql_backup/20130502050029.tar...
		Total: 90 seconds
		
3. You can verify the contents of the base_backup
		
		tar -vtf 20130502050029.tar.gz
		...
		-rw-------  0 pgsql  pgsql      8192 Apr  8 00:13 pgsql/global/11753_vm
		-rw-------  0 pgsql  pgsql     24576 Apr  8 00:13 pgsql/global/11753_fsm
		drwxr-xr-x  0 pgsql  pgsql         0 May  2 05:01 archive/
		-rw-------  0 pgsql  pgsql  16777216 May  2 05:00 archive/0000000500000006000000B9
		-rw-------  0 pgsql  pgsql  16777216 May  2 05:01 archive/0000000500000006000000BA
		-rw-------  0 pgsql  pgsql       248 May  2 05:01 archive/0000000500000006000000BA.00000020.backup
		-rw-------  0 pgsql  pgsql  16777216 May  2 05:01 archive/0000000500000006000000BB
		-rw-r--r--  0 root   wheel        76 May  2 05:01 recovery.local.conf
		
4. If you want to recover from a base backup. See Recovery below.

	
## Streaming Replication Setup

### On Master Server

1. Setup replication user

		CREATE USER repuser SUPERUSER LOGIN CONNECTION LIMIT 1 ENCRYPTED PASSWORD 'changeme';

2. Setup streaming replication parameters on master. See postgresql.master.conf
	
		wal_level = hot_standby
		max_wal_senders = 3
		wal_keep_segments = 32
	
3. Start postgresql

		/usr/local/etc/rc.d/postgresql start
		
4. Make a base backup by copying the primary server's data directory to the standby server. Use base_sync.sh

		pgreplicator/base_sync.sh

5. [optional] Stop postgresql

		/usr/local/etc/rc.d/postgresql stop
		
### On Standby Server
		
1. Stop postgresql

		/usr/local/etc/rc.d/postgresql stop
		
2. Run setup_standby.sh

		/var/db/pgreplicator/setup_standby.sh	


3. Start postgresql

		/usr/local/etc/rc.d/postgresql start
		
### On Master
1. Start postgresql

		/usr/local/etc/rc.d/postgresql start

2. Enable archiving

		pgreplicator/activate_archiving.sh
	
	
### Monitoring Streaming Replication

**On Master**

	# select pg_current_xlog_location();
	
Sample log output from master
	
	LOG:  database system is ready to accept connections
	LOG:  autovacuum launcher started
	LOG:  connection received: host=192.168.4.223 port=37522
	LOG:  replication connection authorized: user=repuser host=192.168.4.223 port=37522
	LOG:  connection received: host=[local]
	LOG:  connection authorized: user=pgsql database=postgres
	Wed May  1 05:05:34 EST 2013: Archiving Inactive.
	Wed May  1 05:06:03 EST 2013: Found /var/db/pgsql_backup/archiving_active. Archiving Active.
	Wed May  1 05:06:03 EST 2013: Archive Locally: cp pg_xlog/00000005000000060000007F /var/db/pgsql_backup/archive/00000005000000060000007F
	Wed May  1 05:06:03 EST 2013: Standby via Remote SSH: cp pg_xlog/00000005000000060000007F pgsql@192.168.4.223:/var/db/pgsql_backup/archive


**On Slave**

	# select pg_last_xlog_receive_location();
	# select pg_last_xlog_replay_location();		
Sample log output from slave
	
	LOG:  entering standby mode
	cp: /var/db/pgsql_backup/archive/000000050000000600000080: No such file or directory
	LOG:  consistent recovery state reached at 6/80DE2CC0
	LOG:  redo starts at 6/80DE2C30
	LOG:  database system is ready to accept read only connections
	LOG:  record with zero length at 6/80DE2CC0
	cp: /var/db/pgsql_backup/archive/000000050000000600000080: No such file or directory
	LOG:  streaming replication successfully connected to primary
	LOG:  connection received: host=[local]
	LOG:  connection authorized: user=pgsql database=postgres
	
A good article on WAL segments http://eulerto.blogspot.com.au/2011/11/understanding-wal-nomenclature.html

	CREATE OR REPLACE FUNCTION hex2int(TEXT) RETURNS bigint AS
	$$
	DECLARE
	result BIGINT;
	BEGIN
		EXECUTE 'SELECT CAST(X'||quote_literal($1)||' AS BIGINT)' INTO result;
		RETURN result;
	END;
	$$
	LANGUAGE plpgsql;
	
	--
	-- Parameters: 1 = xlog master
	-- 2 = xlog replica
	--
	CREATE OR REPLACE FUNCTION pg_replication_lag_bytes(TEXT, TEXT) RETURNS bigint AS
	$$
		SELECT ( hex2int('FF000000') * hex2int( split_part($1, '/', 1) ) + hex2int( split_part($1, '/', 2) ) ) -
		( hex2int('FF000000') * hex2int( split_part($2, '/', 1) ) + hex2int( split_part($2, '/', 		2) ) );
	$$
	LANGUAGE sql;
	
	# SELECT pg_replication_lag_bytes('6/A487A000', '6/A38D0000');
	pg_replication_lag_bytes
	------------------------
                 	16424960
	(1 row)

## Recovery

### Recovery from a base backup
1. Inspect /var/db/pgsql_backup for backup files

		# ls -la /var/db/pgsql_backup
		drwxr-xr-x   4 pgsql  pgsql        512 Apr 24 01:40 .
		drwxr-xr-x  13 root   wheel        512 Apr 24 01:41 ..
		-rw-r--r--   1 root   pgsql  160835646 Apr 23 06:54 20130423065321.tar.gz
		-rw-r--r--   1 root   pgsql  160928215 Apr 23 06:56 20130423065514.tar.gz
		-rw-r--r--   1 root   pgsql  160835728 Apr 23 07:00 20130423065928.tar.gz
		-rw-r--r--   1 root   pgsql  158357103 Apr 23 07:24 20130423072321.tar.gz
	
2. Edit config to configure how we recover

		RECOVERY_MODE=0 #local


3. Stop postgresql
		
		/usr/local/etc/rc.d/postgresql stop
		
4. Recover

		# pgreplicator/recover.sh 20130423072321			
		Extracting 20130423072321.tar.gz...
		Moving archive and recovery.conf to pgsql/...
		Creating pg_log and pg_xlog directories in pgsql..
		Setting permissions to pgsql for 20130423072321...
		Stopping postgres...
		pg_ctl: PID file "/var/db/pgsql/postmaster.pid" does not exist
		Is server running?
		Moving current pgsql to pgsql.old. Its good to have a backup of what happened
		Moving /var/db/pgsql_backup/20130423072321/pgsql to /var/db
		------------------------------------
		Ok we are ready. Lets rock!
		Starting postgresql...
		pg_ctl: another server might be running; trying to start server anyway
		Recovery done!
		You can verify this by:
		a. Checking for recovery.done in pgsql/
		b. Checking for backup_label.old in pgsql/
		c. tail -f pg_log/logfile

## Miscelanneous		

### Reset Log
	
	$ pg_resetxlog /var/db/pgsql
	Transaction log reset
