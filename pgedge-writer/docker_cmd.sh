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

# return the container's name from the given IP address
function subdomain
{
  dig -x "$1" +short | cut -d\. -f1
}

set -x
# start up postgres
su "${PGUSER}" -c '/opt/pg16/bin/pg_ctl start -D /opt/pg16/data'

# As a publisher, create my own node
psql -c "SELECT spock.node_create(node_name:='$(subdomain $(my_ip))', dsn:='host=$(my_ip) port=5432 dbname=${PGDATABASE}')"
#psql -c "create table if not exists public.test_table (id SERIAL PRIMARY KEY, val text)"
psql -c "SELECT spock.repset_add_all_tables('default', ARRAY['public'])"

# As a subscriber, read from all of my peers
for ip in $(my_peer_ips); do
  subscription="${PGDATABASE}_$(subdomain $(my_ip))_$(subdomain ${ip})"
  psql -c "SELECT spock.sub_create(subscription_name:='${subscription}',provider_dsn:='host=${ip} port=5432 dbname=${PGDATABASE}')"
  psql -c "SELECT spock.sub_wait_for_sync('${subscription}')"
done

#sleep 10
# Create a fun test table!!!
#psql -c "select spock.replicate_ddl('create table if not exists public.test_table (id SERIAL PRIMARY KEY, val text)')"
#psql -c "insert into test_table (val) values('hello world from writer $(my_ip)')"

# Sleep forever
sleep infinity
