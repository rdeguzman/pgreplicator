# PostgreSQL Scripts

The scripts below are used to setup archiving in Postgres9.x on FreeBSD9.1

## Quick Howto

1. Clone

		# cd /var/db
		# git clone https://github.com/rdeguzman/pgscripts.git

2. Create initial directories
		
		# sh pgscripts/init.sh
		
3. Config

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
	

## Config
