#!/bin/bash
# Common bash functions used across multiple images

# Return the servie name "writer", "reader", "pgcat", etc
function my_service
{
  dig -x "$(my_ip)" +short | cut -d\. -f1 | perl -pe 's/.*?([^\W_]+)_\d+$/$1/'
}

function my_ip
{
  dig +short $(hostname)
}

# List of IPs of other containers running in my same service
function my_peer_ips
{
  dig +short $(my_service) |sort -n |grep -v $(my_ip)
}

# If we need a count of how many writer replicas
# we've been scaled to in Docker Compose
function writer_count
{
  dig +short writer | wc -l
}

# writer_count - 1
function writer_peer_count
{
  expr $(writer_count) - 1
}

# return the container's name from the given IP address.
# Strip off the prepended name that Docker Compose
# adds from the project directory name.
# So, pgedge-docker-compose_writer_3 returns just "writer_3"
function short_subdomain
{
  dig -x "$1" +short | cut -d\. -f1 | perl -pe 's/.*?([^\W_]+_\d+)$/$1/'
}

# Return a plain integer of my host number, like reader_1 is just '1'
function my_host_number
{
  short_subdomain "$(my_ip)" | perl -pe 's/.*?_(\d+)$/$1/'
}

# Each reader is paired with a single writer to behave 
# as if they were a local replicate in the same datacenter
# as the writer.
function my_writer_hostname
{
  echo "pgedge-docker-compose_writer_$(my_host_number)"
}

# A nice short name for use in the subscription
function my_writer_shortname
{
  echo "writer_$(my_host_number)"
}

# readers need to know who their writer IP address is
function my_writer_ip
{
  dig "$(my_writer_hostname)" +short
}

