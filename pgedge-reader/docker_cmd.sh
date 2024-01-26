#!/bin/bash
# Docker CMD script

source /bash_functions.sh

set -x
# start up postgres
su "${PGUSER}" -c '/opt/postgres/bin/pg_ctl start -D /opt/postgres/data'

# Just on writer nodes, set our snowflake.node number based on our
# hostname that Docker Compose gave us.
# IE:  writer_2 gets a snowflake.node=2
psql -c "ALTER SYSTEM SET snowflake.node = 1$(my_host_number)"
psql -c "SELECT pg_reload_conf()"


# As a subscriber, I still need my own local node created
psql -c "
  SELECT spock.node_create(
    node_name := '$(short_subdomain $(my_ip))',
    dsn := 'host=$(my_ip) port=5432 dbname=${PGDATABASE}'
  )
  "

echo "HERE"
all_writer_ips

# Wait for all writes to finish creating publisher nodes
for ip in $(all_writer_ips); do
  while [[ $(psql -h "${ip}" -t -c "select count(*) from spock.node_info()" |head -1 | tr -d ' ') != "1" ]]; do
    echo "Waiting for ${ip} ($(short_subdomain ${ip})) to finish creating its publisher node..."
  sleep 3
  done
done

# As a subscriber, read from my writer
# NOTE:  I screwed this up.  This method only receives replication from one
# writer.  If I have 3 writers, I only receive 1/3 of the records.
#subscription="${PGDATABASE}_$(my_writer_shortname)_to_$(short_subdomain $(my_ip))"
#psql -c "
#  SELECT spock.sub_create(
#    subscription_name := '${subscription}',
#    forward_origins := '{}',
#    synchronize_structure := true,
#    provider_dsn := 'host=$(my_writer_ip) port=5432 dbname=${PGDATABASE}'
#  )
#"
#psql -c "SELECT spock.wait_slot_confirm_lsn(NULL, NULL)"
#psql -c "SELECT spock.sub_wait_for_sync('${subscription}')"

for ip in $(all_writer_ips); do
  subscription="${PGDATABASE}_$(short_subdomain ${ip})_to_$(short_subdomain $(my_ip))"
  psql -c "
    SELECT spock.sub_create(
      subscription_name := '${subscription}',
      forward_origins := '{}',
      provider_dsn := 'host=${ip} port=5432 dbname=${PGDATABASE}'
    )
  "
  # This is too aggressive of a wait with multi-master and multi-slave
  #psql -c "SELECT spock.wait_slot_confirm_lsn(NULL, NULL)"
  psql -c "SELECT spock.sub_wait_for_sync('${subscription}')"
done

# Wait for all of the writers to finish catching up their subscription replication slots
for ip in $(all_writer_ips); do
  # replicate_count is all writers + all readers - 1  (myself)
  while [[ $(psql -h "${ip}" -t -c "select count(*) from pg_replication_slots" |head -1 | tr -d ' ') != "$(replicate_count)" ]]; do
    echo "Waiting for ${ip} ($(short_subdomain ${ip})) to finish catching up on replication..."
    sleep 3
  done
done

# Wait a bit for masters to insert records
sleep 10

psql -c "select * from test_table"

# Sleep forever
sleep infinity
