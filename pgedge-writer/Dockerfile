FROM pgedge_pgedge-base:latest

ARG PGDATABASE 
ENV PGDATABASE $PGDATABASE

ARG PGUSER
ENV PGUSER $PGUSER

COPY schema.sql /

# Create the PGDATABASE and load the spock extension
RUN su postgres -c '/opt/pg16/bin/pg_ctl start -D /opt/pg16/data' \
  && PGDATABASE=postgres psql -c "create database ${PGDATABASE}" \
  && psql "${PGDATABASE}" -c "create extension spock" \
  && psql "${PGDATABASE}" < /schema.sql \
  && su postgres -c '/opt/pg16/bin/pg_ctl stop -D /opt/pg16/data'

COPY docker_cmd.sh /

CMD /docker_cmd.sh

