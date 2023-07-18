FROM pgedge-base:latest

ARG PGDATABASE 
ENV PGDATABASE $PGDATABASE

ARG PGUSER
ENV PGUSER $PGUSER

#COPY schema.sql /

  #&& psql "${PGDATABASE}" < /schema.sql \
# Create the PGDATABASE and load the spock extension
RUN su postgres -c '/opt/postgres/bin/pg_ctl start -D /opt/postgres/data' \
  && PGDATABASE=postgres psql -c "create database ${PGDATABASE}" \
  && psql "${PGDATABASE}" -c "create extension spock" \
  && su postgres -c '/opt/postgres/bin/pg_ctl stop -D /opt/postgres/data'

COPY docker_cmd.sh /

CMD /docker_cmd.sh

