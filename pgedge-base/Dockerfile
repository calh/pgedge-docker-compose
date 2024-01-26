FROM rockylinux:9

RUN yum install -y \
  bison \
  bison-runtime \
  flex \
  bzip2 \
  dnsutils \
  gcc \
  git \
  iputils \
  krb5-devel \
  libicu-devel \
  make \
  openssl-devel \
  patch \
  perl-FindBin \
  perl-File-Compare \
  procps-ng \
  readline-devel \
  wget \
  zlib-devel
WORKDIR /opt

ARG PGUSER
ENV PGUSER $PGUSER

ARG PG_MAJOR_VERSION
ENV PG_MAJOR_VERSION $PG_MAJOR_VERSION

ARG SPOCK_BRANCH
ENV SPOCK_BRANCH $SPOCK_BRANCH

# Clone spock first, we need the patches before compiling postgres
#   NOTE:  for a real deployment, combining these steps will result in a thinner image
RUN git clone --depth=1 -b ${SPOCK_BRANCH} https://github.com/pgEdge/spock.git /opt/spock

RUN adduser "${PGUSER}" \
  && git clone --depth=1 -b REL_${PG_MAJOR_VERSION}_STABLE https://github.com/postgres/postgres.git postgres.source \
  && cd /opt/postgres.source \
  && patch -p1 < /opt/spock/pg${PG_MAJOR_VERSION}-log_old_value.diff \ 
  && ./configure --prefix=/opt/postgres \ 
  && make -j$(cat /proc/cpuinfo |grep processor |wc -l) \
  && make install \
  && cd /opt/postgres.source/contrib \
  && git clone https://github.com/pgEdge/snowflake.git \
  && cd /opt/postgres.source/contrib/snowflake \
  && make \
  && make install \
  && chown -R "${PGUSER}:${PGUSER}" /opt/postgres \
  && su postgres -c '/opt/postgres/bin/pg_ctl init -D /opt/postgres/data' \
  && rm -Rf /opt/postgres.source

COPY --chown="${PGUSER}":"${PGUSER}" postgresql.conf pg_hba.conf /opt/postgres/data/

ENV PATH="${PATH}:/opt/postgres/bin"

# Install spock
RUN cd /opt/spock \
  && make -j$(cat /proc/cpuinfo |grep processor |wc -l) \
  && make install 

COPY bash_functions.sh /
COPY schema.sql /
