# This file is auto generated from it's template, This Dockerfile use mobilityDB develop version including Citus extension. Cloud version
# see citusdata/tools/packaging_automation/templates/docker/latest/latest.tmpl.dockerfile.
FROM bouzouidja/mobilitydb-develop:latest
ARG VERSION=1.1
ARG CITUS_VERSION=11.1.5



LABEL maintainer="BOUZOUIDJA Sid-Ahmed" \
      org.label-schema.name="CLoud native MobilityDB extension" \
      org.label-schema.description="Scaling PostgreSQL database using Citus extension on top of MobilityDB" \
      org.label-schema.version=${VERSION} \
      org.label-schema.schema-version="1.0"

ENV CITUS_VERS ${CITUS_VERSION}.citus-1

ENV POSTGRES_DBNAME=mobilitydb
ENV POSTGRES_USER=postgres 
ENV POSTGRES_PASSWORD=postgres




# Install Citus
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates \
       build-essential \
       cmake \
       curl \
       git \
    && curl -s https://install.citusdata.com/community/deb.sh | bash \
    && apt-get install -y postgresql-$PG_MAJOR-citus-11.1=$CITUS_VERS \
                          postgresql-$PG_MAJOR-hll=2.17.citus-1 \
                          postgresql-$PG_MAJOR-topn=2.5.0.citus-1 \
    && apt-get purge -y --auto-remove curl \
    && rm -rf /var/lib/apt/lists/*



# add citus to default PostgreSQL config
#RUN echo "shared_preload_libraries='citus'" >> /usr/share/postgresql/postgresql.conf.sample

# add scripts to run after initdb
COPY ./create_extensions.sh /docker-entrypoint-initdb.d/mobilitydb.sh
RUN chmod +x /docker-entrypoint-initdb.d/mobilitydb.sh

# add health check script
COPY pg_healthcheck wait-for-manager.sh /
RUN chmod +x /wait-for-manager.sh

# entry point unsets PGPASSWORD, but we need it to connect to workers
# https://github.com/docker-library/postgres/blob/33bccfcaddd0679f55ee1028c012d26cd196537d/12/docker-entrypoint.sh#L303
RUN sed "/unset PGPASSWORD/d" -i /usr/local/bin/docker-entrypoint.sh



HEALTHCHECK --interval=4s --start-period=6s CMD ./pg_healthcheck