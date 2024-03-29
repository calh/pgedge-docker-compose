#!/bin/bash
# Docker CMD script

source /bash_functions.sh

set -x

# I like a more dynamic config bootstrap, worked out below
#echo "snowflake.node = '$(my_host_number)'" >> /opt/postgres/data/postgresql.auto.conf

# start up postgres
su "${PGUSER}" -c '/opt/postgres/bin/pg_ctl start -D /opt/postgres/data'

# Just on writer nodes, set our snowflake.node number based on our
# hostname that Docker Compose gave us.  
# IE:  writer_2 gets a snowflake.node=2
psql -c "ALTER SYSTEM SET snowflake.node = $(my_host_number)"
psql -c "SELECT pg_reload_conf()"

# As a publisher, create my own node
psql -c "
  SELECT spock.node_create(
    node_name := '$(short_subdomain $(my_ip))',
    dsn := 'host=$(my_ip) port=5432 dbname=${PGDATABASE}'
  )
  "

#psql -c "create table if not exists public.test_table (id SERIAL PRIMARY KEY, val text)"
psql -c "SELECT spock.repset_add_all_tables('default', ARRAY['public'])"
# Don't replicate sequences when using snowflakes
#psql -c "SELECT spock.repset_add_all_seqs('default', ARRAY['public'])"

# Wait for all of my peers to finish creating their publisher node
for ip in $(my_peer_ips); do
  while [[ $(psql -h "${ip}" -t -c "select count(*) from spock.node_info()" |head -1 | tr -d ' ') != "1" ]]; do
    echo "Waiting for ${ip} to finish creating its publisher node..."
    sleep 3
  done
done

# As a subscriber, read from all of my other writer peers
#  Note:  forward_origins as an empty array turns off
#         forwarding queries from another subscription.
#         (That would be for chaining replication, but we have
#         a multi-master bidirectional setup which creates loops)
for ip in $(my_peer_ips); do
  subscription="${PGDATABASE}_$(short_subdomain ${ip})_to_$(short_subdomain $(my_ip))"
  psql -c "
    SELECT spock.sub_create(
      subscription_name := '${subscription}',
      forward_origins := '{}',
      provider_dsn := 'host=${ip} port=5432 dbname=${PGDATABASE}'
    )
  "
  # This is too aggressive to wait for all slots on a multi-master,
  # it frequently hangs 
  #psql -c "SELECT spock.wait_slot_confirm_lsn(NULL, NULL)"
  psql -c "SELECT spock.sub_wait_for_sync('${subscription}')"
done

# TODO:  FIX ME
# Wait for all of my peers to finish catching up their subscription replication slots
for ip in $(my_peer_ips); do
  # replicate_count is all writers + all readers - 1  (myself)
  while [[ $(psql -h "${ip}" -t -c "select count(*) from pg_replication_slots" |head -1 | tr -d ' ') != "$(replicate_count)" ]]; do
    echo "Waiting for ${ip} ($(short_subdomain ${ip})) to finish catching up on replication..."
    sleep 3
  done
done

# Wait a bit to just let things settle out before we insert
sleep 5

#psql -c "ALTER SYSTEM SET snowflake.node = $(my_host_number)"
# Create a hello world record from myself!

# Problem:  race condition where we try to insert id==1 due
#           to the sequence not replicating fast enough
psql -c "insert into test_table (val) values('hello world from writer $(short_subdomain $(my_ip))')"

# Problem:  Causes `ERROR: tuple concurrently updated`
#       Seems less frequent though...
#psql -c "insert into test_table (val)
#  values('hello world from writer $(short_subdomain $(my_ip))');
#  select * from spock.sync_seq('test_table_id_seq')"

# Problem:  Using a transaction just seems to change the error message from
#   "tuple concurrently updated" to "conflict resolution: keep local"
#   One record still fails.
#psql -c "begin ; insert into test_table (val) values('hello world from writer $(short_subdomain $(my_ip))') ; commit"

psql -c "select * from test_table"

# Sleep a second and then select again
sleep 1
psql -c "select * from test_table"

# Sleep forever
sleep infinity
