# PostgreSQL Scripts

The scripts below are used to setup archiving in Postgres9.x on FreeBSD9.1

## Main Features
- Local Archiving
- Remote Archiving via SSH

## Quick Howto

1. Clone

		# cd /var/db
		# git clone https://github.com/rdeguzman/pgscripts.git

2. Create initial directories
		
		# sh pgscripts/init.sh
		
3. Adjust configurations in config file

		# cat pgscripts/config
		PGDATA="/var/db/pgsql"
		PGBACKUP_DIR="/var/db/pgsql_backup"
		PGARCHIVE_DIR=$PGBACKUP_DIR/archive
		PGARCHIVE_TRIGGER_FILE=$PGBACKUP_DIR/archiving_active

		# 0: local
		# 1: remote via rsync
		PGARCHIVE_MODE="0"
	

4. Manually edit postgresql.conf.

		# vim postgresql.conf
		archive_mode = on # allows archiving to be done
		archive_command = '../pgscripts/archive.sh %p %f'
		archive_timeout = 30
		
 	Change requires a postgresql restart
 	
 		# /usr/local/etc/rc.d/postgresql stop
		# /usr/local/etc/rc.d/postgresql start
 		
5. Take a base backup
	

##Archiving
### Local (0)

Archives WAL segments to a local directory as specified in **$ARCHIVE_DIR**

### Remote via SSH (1)
Archives WAL segments to a remote server as specified in:

* $ARCHIVE_DIR
* $ARCHIVE_USER - normally this is pgsql
* ARCHIVE_SERVER
* ARCHIVE_SERVER_SSH_PORT

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
	
On the **archive** server:

	# su -l pgsql
	# cd /usr/local/pgsql
	# mkdir .ssh
	# cat master.pub >> .ssh/authorized_keys
	
Test by copying a file from **master** to **archive** using scp

	scp foo pgsql@archive_server:/usr/local/pgsql/	

