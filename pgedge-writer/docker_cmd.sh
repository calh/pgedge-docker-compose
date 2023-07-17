#!/bin/bash
# Docker CMD script

function my_ip
{
  dig +short $(hostname)
}

function my_peer_ips
{
  dig +short writer |sort -n |grep -v $(my_ip)
}

# If we need a count of how many writer replicas
# we've been scaled to in Docker Compose
function writer_count
{
  dig +short writer | wc -l
}

# writer_count - 1 
function peer_count
{
  expr $(writer_count) - 1
}

# return the container's name from the given IP address.
# Also strip off the prepended name that Docker Compose 
# adds from the project directory name
function subdomain
{
  dig -x "$1" +short | cut -d\. -f1 | sed 's|.*\(writer_.*\)$|\1|'
}

set -x
# start up postgres
su "${PGUSER}" -c '/opt/postgres/bin/pg_ctl start -D /opt/postgres/data'

#sleep infinity

# As a publisher, create my own node
psql -c "
  SELECT spock.node_create(
    node_name := '$(subdomain $(my_ip))',
    dsn := 'host=$(my_ip) port=5432 dbname=${PGDATABASE}'
  )
  "

#psql -c "create table if not exists public.test_table (id SERIAL PRIMARY KEY, val text)"
psql -c "SELECT spock.repset_add_all_tables('default', ARRAY['public'])"
psql -c "SELECT spock.repset_add_all_seqs('default', ARRAY['public'])"

# Wait for all of my peers to finish creating their publisher node
for ip in $(my_peer_ips); do
  while [[ $(psql -h "${ip}" -t -c "select count(*) from spock.node_info()" |head -1 | tr -d ' ') != "1" ]]; do
    echo "Waiting for ${ip} to finish creating its publisher node..."
    sleep 3
  done
done
# As a subscriber, read from all of my peers
#  Note:  forward_origins as an empty array turns off
#         forwarding queries from another subscription.
#         (That would be for chaining replication, but we have
#         a multi-master bidirectional setup which creates loops)
for ip in $(my_peer_ips); do
  subscription="${PGDATABASE}_$(subdomain ${ip})_to_$(subdomain $(my_ip))"
  psql -c "
    SELECT spock.sub_create(
      subscription_name := '${subscription}',
      forward_origins := '{}',
      provider_dsn := 'host=${ip} port=5432 dbname=${PGDATABASE}'
    )
  "
  psql -c "SELECT spock.wait_slot_confirm_lsn(NULL, NULL)"
  psql -c "SELECT spock.sub_wait_for_sync('${subscription}')"
done

# Wait for all of my peers to finish catching up their subscription replication slots
for ip in $(my_peer_ips); do
  while [[ $(psql -h "${ip}" -t -c "select count(*) from pg_replication_slots" |head -1 | tr -d ' ') != "$(peer_count)" ]]; do
    echo "Waiting for ${ip} to finish catching up on replication..."
    sleep 3
  done
done

sleep 10
# Create a hello world record from myself!

# Problem:  race condition where we try to insert id==1 due
#           to the sequence not replicating fast enough
psql -c "insert into test_table (val) values('hello world from writer $(subdomain $(my_ip))')"

# Problem:  Causes `ERROR: tuple concurrently updated`
#       Seems less frequent though...
#psql -c "insert into test_table (val)
#  values('hello world from writer $(subdomain $(my_ip))');
#  select * from spock.sync_seq('test_table_id_seq')"

# Problem:  Using a transaction just seems to change the error message from
#   "tuple concurrently updated" to "conflict resolution: keep local"
#   One record still fails.
#psql -c "begin ; insert into test_table (val) values('hello world from writer $(subdomain $(my_ip))') ; commit"

psql -c "select * from test_table"

# Sleep a second and then select again
sleep 1
psql -c "select * from test_table"

# Sleep forever
sleep infinity
