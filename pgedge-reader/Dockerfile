FROM pgedge-base:latest

ARG PGDATABASE 
ENV PGDATABASE $PGDATABASE

ARG PGUSER
ENV PGUSER $PGUSER


  #&& psql "${PGDATABASE}" -c "create extension snowflake" \
# Create the PGDATABASE and load the spock and snowflake extensions
RUN su postgres -c '/opt/postgres/bin/pg_ctl start -D /opt/postgres/data' \
  && PGDATABASE=postgres psql -c "create database ${PGDATABASE}" \
  && psql "${PGDATABASE}" -c "create extension spock" \
  && psql "${PGDATABASE}" -c "create extension snowflake" \
  && psql "${PGDATABASE}" < /schema.sql \
  && su postgres -c '/opt/postgres/bin/pg_ctl stop -D /opt/postgres/data'

COPY docker_cmd.sh /

CMD /docker_cmd.sh

