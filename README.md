# Experimental Docker Compose pgEdge

Rather than rely on all of the dynamically created stuff 
with Python scripts, I wanted to try to construct a 
pgEdge demonstration with plain Docker techniques

This is a work in progress for now.

Directories:

* `from_packages` - installs tarball packages from the same S3 repo as nodectl

Branches:

* `from_source` - builds postgres and spock from source.  Keeping this locked to demo a bug.
* `snowflake_collision` - Locking this to show snowflake causing collisions

### New -- Snowflake Support

Added Snowflake sequences to show that work better than integer sequences.  
Each of the 3 masters loads the snowflake extension, and then sets `snowfake.node` postgres.conf 
to the integer number of the current master slot.  (IE:  `master_2` gets node `2`)

To stress test inserting records:

```
$ ./script/stress_test_writer.sh 20 20000

/pgedge-docker-compose_writer_3: INSERT 0 20000
/pgedge-docker-compose_writer_2: INSERT 0 20000
/pgedge-docker-compose_writer_2: INSERT 0 20000
```

```
USAGE: ./script/stress_test_writer.sh [n] [records]

Where n is the number of query iterations and
records is how many records to insert for each iteration

This will concurrently perform the test against all writers
```

