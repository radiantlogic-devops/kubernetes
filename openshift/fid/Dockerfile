################################################################################
# Build stage 0
# Extract FID base files
################################################################################
ARG BASE_REGISTRY=registry1.dso.mil
ARG BASE_IMAGE=ironbank/redhat/ubi/ubi8
ARG BASE_TAG=8.4

FROM radiantone/fid:7.3.16 as base

RUN chmod -R g=u /opt/radiantone


################################################################################
# Build stage 1
# Copy prepared files from the previous stage and complete the image.
################################################################################
FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG}

RUN yum update --setopt=tsflags=nodocs -y && \
      yum install -y hostname nc && \
      yum clean all

# Copy file from FID image
COPY --from=base --chown=1000:0 /opt/radiantone /opt/radiantone

# Provide a non-root user to run the process.
#RUN groupadd --gid 0 radiantone && \
RUN useradd --uid 1000 --gid 0 -G 0 \
      --home-dir /opt/radiantone --no-create-home \
      radiantone

USER radiantone

RUN chmod -R g=u /opt/radiantone

# Make the file run.sh executable
#RUN chmod +x /opt/radiantone/run.sh && chmod +x /opt/radiantone/update.sh \
#	&& chmod +x /opt/radiantone/install.sh && chmod +x /opt/radiantone/migrate.sh \
#        && chmod +x /opt/radiantone/migrate-local.sh

WORKDIR /opt/radiantone

ENV PATH=/opt/radiantone/vds/bin:/opt/radiantone/vds/bin/advanced:$PATH
ENV RLI_HOME=/opt/radiantone/vds
ENV LIVENESS_CHECK="curl -m 1 -sf localhost:9100/ping"

EXPOSE 2389 2636 7070 7171 8089 8090 9100 9101

ENTRYPOINT ["/opt/radiantone/run.sh"]
CMD ["fg"]

HEALTHCHECK --interval=10s --timeout=5s --start-period=1m --retries=5 CMD curl -I -f --max-time 5 http://localhost:9100 || exit 1





















