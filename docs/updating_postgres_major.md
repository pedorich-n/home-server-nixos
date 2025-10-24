# Updating PostgreSQL major version

Updating PostgreSQL to a next major release usually means that the storage format changes and the data has to be manually migrated.

## Steps

1.  Dump all data from the existing DB using `podman exec <service>-postgresql pg_dumpall -U <user> > <service>_dumpall_$(date +%F).sql`
2.  Stop the service and the DB. For example `systemctl stop <service>.service`
3.  Move the existing data to a new location. For example `cd /mnt/store/<service>; mv postgresql postgresql-17`
4.  Create new data folder with proper permissions.
5.  Pull the new version of the container. For example `podman pull postgres:18.0-alpine`
6.  Run a one-off container with the new version using the same ENVs and mounts as the service's one. For example: `podman run -d --name postgres18 --env-file=/run/secrets/<service>/postgresql.env -v /mnt/store/<service>/postgresql:/var/lib/postgresql/data postgres:18.0-alpine`
7.  Restore previously backed up data to this temporary container: `cat ./<service>_dumpall_<date>.sql | podman exec -i postgres18 psql -U <user>`
8.  Stop and remove the temporary container. For example `podman stop postgres18`, `podman container rm postgres18`
9.  Deploy the service with the new version of PostgreSQL
