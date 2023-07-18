#!/bin/bash
# Docker CMD script

source /bash_functions.sh

set -x
# start up postgres
su "${PGUSER}" -c '/opt/postgres/bin/pg_ctl start -D /opt/postgres/data'

#sleep infinity

# As a subscriber, I still need my own local node created
psql -c "
  SELECT spock.node_create(
    node_name := '$(short_subdomain $(my_ip))',
    dsn := 'host=$(my_ip) port=5432 dbname=${PGDATABASE}'
  )
  "

# Wait for my writer to finish creating their publisher node
while [[ $(psql -h "$(my_writer_ip)" -t -c "select count(*) from spock.node_info()" |head -1 | tr -d ' ') != "1" ]]; do
  echo "Waiting for $(my_writer_hostname) to finish creating its publisher node..."
  sleep 3
done

# As a subscriber, read from my writer
subscription="${PGDATABASE}_$(my_writer_shortname)_to_$(short_subdomain $(my_ip))"
psql -c "
  SELECT spock.sub_create(
    subscription_name := '${subscription}',
    forward_origins := '{}',
    synchronize_structure := true,
    provider_dsn := 'host=$(my_writer_ip) port=5432 dbname=${PGDATABASE}'
  )
"
psql -c "SELECT spock.wait_slot_confirm_lsn(NULL, NULL)"
psql -c "SELECT spock.sub_wait_for_sync('${subscription}')"

# Wait for all of my peers to finish catching up their subscription replication slots
#for ip in $(my_peer_ips); do
#  while [[ $(psql -h "${ip}" -t -c "select count(*) from pg_replication_slots" |head -1 | tr -d ' ') != "$(peer_count)" ]]; do
#    echo "Waiting for ${ip} to finish catching up on replication..."
#    sleep 3
#  done
#done

#sleep 10
# Create a hello world record from myself!

# Problem:  race condition where we try to insert id==1 due
#           to the sequence not replicating fast enough
#psql -c "insert into test_table (val) values('hello world from writer $(short_subdomain $(my_ip))')"

# Problem:  Causes `ERROR: tuple concurrently updated`
#       Seems less frequent though...
#psql -c "insert into test_table (val)
#  values('hello world from writer $(short_subdomain $(my_ip))');
#  select * from spock.sync_seq('test_table_id_seq')"

# Problem:  Using a transaction just seems to change the error message from
#   "tuple concurrently updated" to "conflict resolution: keep local"
#   One record still fails.
#psql -c "begin ; insert into test_table (val) values('hello world from writer $(short_subdomain $(my_ip))') ; commit"

#psql -c "select * from test_table"

# Sleep a second and then select again
#sleep 1
#psql -c "select * from test_table"

# Sleep forever
sleep infinity
