#!/bin/bash
# simple test, select all values from all writers
ROOT=$(cd -P -- "$(dirname -- "$0")" && printf '%s\n' "$(pwd -P)")
$ROOT/foreach writer psql -c "select * from test_table"
