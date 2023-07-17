#!/bin/bash
# simple test, insert a record on the #1 writer
docker-compose exec writer psql -c "insert into test_table (val) values('hello world from first writer')"
