FROM postgres:16-bookworm

LABEL org.opencontainers.image.source="https://github.com/mamahoos/pgsync"
LABEL org.opencontainers.image.description="PostgreSQL logical sync (pg_dump | psql)"

COPY pgsync.sh /usr/local/bin/pgsync
RUN chmod 755 /usr/local/bin/pgsync

ENTRYPOINT ["pgsync"]
CMD ["--help"]
