#!/bin/bash
ROOT=$(cd -P -- "$(dirname -- "$0")/.." && printf '%s\n' "$(pwd -P)")

if [[ "$1" == "" ]]; then
  echo "USAGE: $0 [n] [records]"
  echo
  echo "Where n is the number of query iterations and"
  echo "records is how many records to insert for each iteration"
  echo
  echo "This will concurrently perform the test against all writers"
  exit
fi

writers=()
for container_id in $(docker-compose ps -q writer); do
  container=$(docker inspect -f '{{.Name}}' $container_id)
  writers+=("$container")
done

n=$1
records=$2

for writer in ${writers[@]}; do
  # Background subshell to concurrently write to all 3 writers
  (
    start=$(date '+%s')
    for i in $(seq 1 $n); do
      echo -n "$writer: "
      docker exec -i $writer psql -c "insert into test_table (val) SELECT random()::text from generate_series(1,$records)"
    done
    elapsed=$(expr "$(date '+%s')" - "$start")
    wps=$(expr "$records" / "$elapsed")
    echo "Finished on $writer in $elapsed seconds, $wps writes per second"
  ) &
done
