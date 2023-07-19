FROM rust:1 AS builder

RUN git clone --depth=1 https://github.com/postgresml/pgcat.git \
  && cd pgcat \
  && cargo build --release

FROM pgedge-base:latest
COPY --from=builder /pgcat/target/release/pgcat /opt/postgres/bin/pgcat
COPY pgcat.toml /etc/pgcat/pgcat.toml
CMD ["/opt/postgres/bin/pgcat /etc/pgcat/pgcat.toml"]
