FROM rockylinux:9

#RUN yum install -y \
#  curl \
#  sudo \
#  procps \
#  vim \
#  unzip \
#  && \
RUN yum install -y \
  bzip2 \
  dnsutils \
  gcc \
  iputils \
  krb5-devel \
  make \
  openssl-devel \
  procps-ng \
  wget
WORKDIR /opt
#RUN python3 -c "$(curl -fsSL https://pgedge-download.s3.amazonaws.com/REPO/install.py)"

# install nodectl + pgedge 
#RUN wget https://github.com/pgEdge/nodectl/archive/refs/tags/v23.121.tar.gz -O nodectl.tar.gz \
#  && tar xzvf nodectl.tar.gz
RUN wget https://pgedge-download.s3.amazonaws.com/REPO/pgedge-nodectl-23.121.tar.bz2 -O pgedge-nodectl.tar.bz2 \
  && tar xvf pgedge-nodectl.tar.bz2 \
  && /opt/pgedge/nodectl set GLOBAL REPO https://pgedge-download.s3.amazonaws.com/REPO \
  && /opt/pgedge/nodectl update \
  && /opt/pgedge/nodectl info \
  && rm -f /opt/pgedge-nodectl.tar.bz2

ARG PGUSER
ENV PGUSER $PGUSER

# Install postgres
RUN adduser "${PGUSER}" \
  && wget https://pgedge-download.s3.amazonaws.com/REPO/pg16-16beta2-1-el9.tar.bz2 -O pg16.tar.bz2 \
  && tar xvf pg16.tar.bz2 \
  && chown -R "${PGUSER}:${PGUSER}" /opt/pg16 \
  && su - "${PGUSER}" -c '/opt/pg16/bin/initdb /opt/pg16/data' \
  && rm -f /opt/pg16.tar.bz2 

COPY postgresql.conf pg_hba.conf /opt/pg16/data/

#  && /opt/pgedge/nodectl config pg16 --port=5432
ENV PATH="${PATH}:/opt/pg16/bin"

# Install spock
#  all of these fail to compile
#RUN wget https://github.com/pgEdge/spock/archive/refs/tags/v3.1.1.tar.gz -O spock.tar.gz \
#RUN wget https://github.com/pgEdge/spock/archive/refs/tags/v3.0.23.tar.gz -O spock.tar.gz \
#RUN wget https://github.com/pgEdge/spock/archive/refs/tags/v3.1.0.tar.gz -O spock.tar.gz \
#  && tar xvf spock.tar.gz \
#  && rm -f spock.tar.gz \
#  && cd /opt/spock* 
#  && make 

RUN wget https://pgedge-download.s3.amazonaws.com/REPO/spock31-pg16-3.1.3-1-el9.tar.bz2 -O spock.tar.bz2 \
  && tar xvf spock.tar.bz2 \
  && rm -f spock.tar.bz2 \
  && cp -av spock*/lib/postgresql/* pg16/lib/postgresql/ \
  && cp -av spock*/share/postgresql/extension/* pg16/share/postgresql/extension/ \
  && su "${PGUSER}" -c '/opt/pg16/bin/pg_ctl start -D /opt/pg16/data' \
  && psql -c 'create extension spock' \
  && su "${PGUSER}" -c '/opt/pg16/bin/pg_ctl stop -D /opt/pg16/data' 
