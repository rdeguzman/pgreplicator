PGDATA="/var/db/pgsql"
PGBACKUPDIR="/var/db/pgsql_backup"

mkdir -p $PGBACKUPDIR
mkdir -p $PGBACKUPDIR/archive
chown -Rf pgsql:pgsql $PGBACKUPDIR

