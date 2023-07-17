#!/bin/bash
# simple test, select all values from all writers
for container in $(docker-compose ps -q writer); do
  echo "$container"
  docker exec -ti $container psql -c "select * from test_table"
done
